# Docker development stack

Optional **Docker Compose** setup for contributors. This folder is the **build context** for all images (`build.context: .` in `docker-compose.yml`).

| Doc | Contents |
|-----|----------|
| **[DEVELOPMENT-FORK.md](DEVELOPMENT-FORK.md)** | Full fork workflow (Spanish): services, ports, UI on host with HMR, pnpm/yarn, release/patch notes |

End-user installs via `get.casaos.io` do **not** use these files — see the main [README.md](../README.md).

## Quick start

From this directory:

```bash
docker compose up -d --build
```

## Layout

- **`../`** — CasaOS repository root (mounted at `/src` in the `casaos` service).
- **`../../CasaOS-UI`** — Expected sibling clone of [CasaOS-UI](https://github.com/IceWhaleTech/CasaOS-UI) for the `ui-dev` service. Edit `docker-compose.yml` if your path differs.

## Files

| File | Role |
|------|------|
| `docker-compose.yml` | ecosystem + API + optional ui-dev |
| `Dockerfile` | Go + Air for hot reload |
| `Dockerfile.ecosystem` | Gateway, Message Bus, User Service, Local Storage, App Management, bundled UI |
| `ecosystem-entrypoint.sh` | Entry script for the ecosystem image |
| `Dockerfile.ui` | Node/pnpm for `pnpm dev` inside Docker |
