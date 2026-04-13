FROM golang:1.25-bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc libc6-dev ca-certificates smartmontools && \
    rm -rf /var/lib/apt/lists/*

RUN go install github.com/air-verse/air@latest

RUN mkdir -p /etc/casaos \
             /var/lib/casaos/db \
             /var/lib/casaos/conf \
             /var/log/casaos \
             /var/run/casaos \
             /usr/share/casaos/shell

WORKDIR /src

EXPOSE 8089

CMD ["air", "-c", ".air.toml"]
