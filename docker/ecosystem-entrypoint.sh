#!/bin/bash
set -e

mkdir -p /var/run/casaos /var/log/casaos /var/lib/casaos/db /var/lib/casaos/conf

# Avoid stale gateway routes from a previous run (volume persists).
rm -f /var/run/casaos/management.url \
      /var/run/casaos/message-bus.url \
      /var/run/casaos/user-service.url \
      /var/run/casaos/local-storage.url \
      /var/run/casaos/app-management.url \
      /var/run/casaos/static.url \
      /var/run/casaos/routes.json \
      /var/run/casaos/gateway.pid

# When CASAOS_WWW_BIND=1, www is a host bind-mount with the fork build — do not copy the upstream tarball
# (would overwrite the mount and pollute the repo with release bits if the directory was empty).
if [ ! -f /var/lib/casaos/www/index.html ] && [ -d /opt/casaos-www ]; then
    if [ "${CASAOS_WWW_BIND:-0}" = "1" ]; then
        echo "ERROR: /var/lib/casaos/www has no index.html. Build the UI and populate CasaOS/build/sysroot/var/lib/casaos/www/ (see CasaOS/docker/DEVELOPMENT-FORK.md)." >&2
        exit 1
    fi
    cp -a /opt/casaos-www/* /var/lib/casaos/www/
fi

# Seed config defaults on first run (Docker volume may hide image files).
if [ -d /opt/casaos-etc ]; then
    cp -an /opt/casaos-etc/* /etc/casaos/ || true
fi
if [ ! -f /etc/casaos/local-storage.conf ] && [ -f /etc/casaos/local-storage.conf.sample ]; then
    cp /etc/casaos/local-storage.conf.sample /etc/casaos/local-storage.conf
fi
if [ ! -f /etc/casaos/app-management.conf ] && [ -f /etc/casaos/app-management.conf.sample ]; then
    cp /etc/casaos/app-management.conf.sample /etc/casaos/app-management.conf
fi

echo "==> Starting CasaOS Gateway..."
casaos-gateway &
GATEWAY_PID=$!

for i in $(seq 1 30); do
    if [ -f /var/run/casaos/management.url ]; then
        echo "    Gateway management ready: $(cat /var/run/casaos/management.url)"
        break
    fi
    sleep 1
done

echo "==> Starting CasaOS Message Bus..."
casaos-message-bus &
MSGBUS_PID=$!

for i in $(seq 1 30); do
    if [ -f /var/run/casaos/message-bus.url ]; then
        echo "    Message Bus ready: $(cat /var/run/casaos/message-bus.url)"
        break
    fi
    sleep 1
done

echo "==> Starting CasaOS User Service..."
casaos-user-service &
USERSVC_PID=$!

for i in $(seq 1 30); do
    if [ -f /var/run/casaos/user-service.url ]; then
        echo "    User Service ready: $(cat /var/run/casaos/user-service.url)"
        break
    fi
    sleep 1
done

echo "==> Starting CasaOS Local Storage..."
casaos-local-storage &
LOCALSTORAGE_PID=$!

for i in $(seq 1 30); do
    if [ -f /var/run/casaos/local-storage.url ]; then
        echo "    Local Storage ready: $(cat /var/run/casaos/local-storage.url)"
        break
    fi
    if [ "$i" = "5" ]; then
        echo "    Local Storage URL file not found yet, continuing startup..."
        break
    fi
    sleep 1
done

echo "==> Starting CasaOS App Management..."
casaos-app-management &
APPMGMT_PID=$!

for i in $(seq 1 30); do
    if [ -f /var/run/casaos/app-management.url ]; then
        echo "    App Management ready: $(cat /var/run/casaos/app-management.url)"
        break
    fi
    sleep 1
done

echo "==> Ecosystem ready. Waiting for processes..."
wait -n $GATEWAY_PID $MSGBUS_PID $USERSVC_PID $LOCALSTORAGE_PID $APPMGMT_PID
