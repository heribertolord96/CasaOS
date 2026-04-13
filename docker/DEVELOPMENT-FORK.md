# CasaOS — fork de desarrollo (backend + UI)

Entorno de trabajo: repositorio **`CasaOS`** (Go, API principal) y clone hermano **`CasaOS-UI`** (Vue 2.7). Los archivos de **Docker Compose** viven en **`CasaOS/docker/`** (context de build: este directorio) y levantan el ecosistema de servicios (Gateway, UserService, AppManagement, etc.) y el backend en caliente con **Air**.

---

## Requisitos

- **Docker** y **Docker Compose** v2
- **Go** (opcional, solo si compilas el backend fuera de Docker)
- **Node.js 18+** y **pnpm** (recomendado) para la UI en modo desarrollo local

---

## Estructura de directorios

Para los volúmenes por defecto del `docker-compose.yml`:

```text
<directorio-padre>/
  CasaOS/                 ← este repositorio (backend)
    docker/               ← ejecuta `docker compose` aquí
      docker-compose.yml
      Dockerfile
      ...
  CasaOS-UI/              ← clone hermano de la UI
```

Si tu `CasaOS-UI` está en otra ruta, edita el volumen del servicio `ui-dev` en `docker-compose.yml`.

---

## Stack Docker (entorno de desarrollo)

Desde **`CasaOS/docker/`**:

```bash
cd docker
docker compose up -d --build
```

(Ruta absoluta de ejemplo: `…/CasaOS/docker`.)

### Servicios

| Servicio     | Rol |
|-------------|-----|
| **ecosystem** | Gateway (Nginx en el puerto interno 80), MessageBus, UserService, LocalStorage, AppManagement; la UI se sirve desde **`CasaOS/build/sysroot/var/lib/casaos/www/`** (bind mount → `/var/lib/casaos/www`), es decir **tu build del fork**, no el tarball solo-imagen |
| **casaos**    | Binario **CasaOS** (Go) con **Air**; comparte red con `ecosystem` (`network_mode: service:ecosystem`) |
| **ui-dev**    | *(Opcional)* contenedor Node que ejecuta `pnpm dev` dentro de Docker (mapeo `4081→8080` en el host) |

### Puertos en el host

| Puerto | Uso |
|--------|-----|
| **4080** | Gateway: **UI del fork** (carpeta anterior) + API (`/v1`, `/v2`) |
| **4081** | Solo si levantas el servicio **ui-dev**: dev server Webpack dentro del contenedor |

**Nota:** el contenedor `ecosystem` monta **`/var/run/docker.sock`** para que App Management pueda listar contenedores y el grid de apps funcione.

### Si `http://localhost:4080/` devuelve `{"message":"Not Found"}` o el navegador dice “invalid response”

El Gateway solo sirve la SPA en `/` si **`/var/lib/casaos/www/index.html`** existe **dentro** del contenedor `ecosystem`. Esa ruta es un **bind mount** a `CasaOS/build/sysroot/var/lib/casaos/www/`.

1. Comprueba en el host que exista **`CasaOS/build/sysroot/var/lib/casaos/www/index.html`** (tras `pnpm build` en **CasaOS-UI** y copiar/rsync al árbol **CasaOS**, como arriba).
2. Si borraste o recreaste esa carpeta **con el contenedor ya en marcha**, el mount de Docker puede quedar colgado (en Linux a veces aparece como `//deleted` en `findmnt`). **Reinicia el stack** para volver a enlazar la ruta:
   ```bash
   cd CasaOS/docker
   docker compose restart ecosystem
   # o: docker compose down && docker compose up -d
   ```
3. Verificación rápida:
   ```bash
   docker exec casaos-ecosystem ls -la /var/lib/casaos/www/index.html
   curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:4080/
   ```
   Deberías ver el fichero y código **200**.

### UI empaquetada en el puerto 4080 (obligatorio antes del primer `up`)

El `docker-compose.yml` monta **`../build/sysroot/var/lib/casaos/www`** (desde la raíz del repo **CasaOS**) en **`/var/lib/casaos/www`**. Así **http://localhost:4080** usa la misma UI que instalarías en un host con tu fork.

1. Genera los estáticos: en **`CasaOS-UI`**, `pnpm install && pnpm run build`.
2. Copia el resultado a **`CasaOS/build/sysroot/var/lib/casaos/www/`** (por ejemplo `rsync -a --delete CasaOS-UI/build/sysroot/var/lib/casaos/www/ CasaOS/build/sysroot/var/lib/casaos/www/`).
3. Desde **`CasaOS/docker/`**, `docker compose build ecosystem` (si cambió `ecosystem-entrypoint.sh`) y `docker compose up -d`.

Si esa carpeta no contiene **`index.html`**, el arranque de **ecosystem** falla a propósito (evita rellenar el directorio con el tarball upstream y ensuciar el repo).

---

## Desarrollo con UI en el host (recomendado: HMR rápido)

1. **Levanta solo el stack que necesitas** (al menos `ecosystem` + `casaos`; puedes omitir `ui-dev`):

   ```bash
   cd docker
   docker compose up -d ecosystem casaos
   ```

2. **Instala dependencias y arranca la UI** en otra terminal:

   ```bash
   cd ../CasaOS-UI
   corepack enable && corepack prepare pnpm@9.0.6 --activate   # si no tienes pnpm
   pnpm install
   pnpm dev --port 5173
   ```

   (Ajusta la ruta si tu clone de **CasaOS-UI** no está junto a **CasaOS**.)

3. Abre **`http://localhost:5173`**. El proxy de Webpack envía `/v1` y `/v2` al Gateway en **`localhost:4080`** (definido en **`.env.dev`** como `VUE_APP_DEV_IP` + `VUE_APP_DEV_PORT`).

4. El backend Go sigue en Docker con recarga (**Air**); la API real está detrás del puerto **4080**.

---

## ¿Yarn en lugar de pnpm?

- El proyecto declara **`packageManager": "pnpm@9.0.6"`** y el lockfile es **`pnpm-lock.yaml`**.
- **pnpm** es lo soportado de forma explícita y reproducible.
- **Yarn** (classic o Berry) puede servir para instalar y ejecutar los mismos scripts (`yarn install`, `yarn dev`, `yarn build`), pero:
  - generará **`yarn.lock`** y no usará el lock de pnpm → versiones pueden diferir;
  - en monorepos/workspaces el comportamiento puede variar.
- **Recomendación:** usa **pnpm** para alinear con el fork y CI; si usas yarn, fija versiones y revisa el build antes de publicar.

---

## Build de la UI y salida

Desde el directorio **`CasaOS-UI`**:

```bash
pnpm install
pnpm run build
```

El script de build deja los estáticos en:

`CasaOS-UI/build/sysroot/var/lib/casaos/www/`

Esa ruta replica el layout que usa el paquete oficial de CasaOS (sysroot → `/var/lib/casaos/www` en el sistema objetivo).

---

## Integrar esta UI en el árbol `CasaOS` (build conjunto)

En **`CasaOS/Makefile`** (o en tu CI) puedes encadenar UI + backend, por ejemplo:

```bash
cd CasaOS && make build-ui build-backend
```

`build-ui` debe ejecutar `pnpm install && pnpm run build` dentro de **`CasaOS-UI`** (ajusta el Makefile de tu fork si aún usa `yarn`).

Copia o empaqueta el contenido generado en **`CasaOS-UI/build/sysroot/var/lib/casaos/www/`** al paquete que instala CasaOS en **`/var/lib/casaos/www`**, según el script de release que uses en tu fork.

---

## Parchear un CasaOS “de serie” con un release de este fork

Cuando publiques un **release** (tarball o artefactos) de **tu fork**:

### 1. Backup

- Copia de **`/var/lib/casaos/www`** (UI).
- Copia del binario **`casaos`** (o del paquete `.deb` completo) si también sustituyes backend.
- Exporta/config de **`/etc/casaos`** y bases en **`/var/lib/casaos`** si procede.

### 2. Sustituir solo la UI

1. Detén el Gateway o el servicio que sirva la UI (según tu distro: `systemctl stop casaos-gateway` o equivalente).
2. Sustituye el contenido de **`/var/lib/casaos/www`** por el de  
   `build/sysroot/var/lib/casaos/www/` generado por **`pnpm build`** de **tu** `CasaOS-UI`.
3. Ajusta permisos (`chown`/`chmod` como el paquete original).
4. Reinicia los servicios CasaOS / Gateway.

### 3. Sustituir también el backend (binario Go)

Solo si tu release incluye cambios en **`CasaOS`**: reemplaza el binario instalado por el que generes con `go build` o el artefacto del release, y reinicia el servicio **`casaos`** (nombre exacto depende del paquete).

### 4. Versiones

- Anota la versión de **CasaOS** y de **CasaOS-UI** compatibles con el release.
- Tras un **`apt upgrade`** oficial, tu UI personalizada puede sobrescribirse: vuelve a aplicar el parche o pin de paquetes según tu estrategia.

---

## Resumen rápido

| Objetivo | Comando / nota |
|----------|----------------|
| Auditoría / tests sin Go ni pnpm en el host | `./scripts/docker-verify.sh` (si existe en tu fork; usa imágenes `golang:1.25-bookworm` y `node:18-bookworm-slim`). El API Go usa **`labstack/echo-jwt/v4`** para JWT con Echo reciente. |
| Stack dev (API + ecosistema) | Build UI → copiar a **`CasaOS/build/.../www`** → `docker compose up -d` desde **`CasaOS/docker/`** |
| UI con hot-reload | `cd CasaOS-UI && pnpm dev --port 5173` + Gateway en **4080** |
| Build UI para producción | `cd CasaOS-UI && pnpm build` → `build/sysroot/var/lib/casaos/www/` |
| CasaOS ya instalado | Copiar esa carpeta a **`/var/lib/casaos/www`** con backup previo |

Para la visión general del proyecto y la instalación en host, consulta **[README.md](../README.md)** en la raíz de **CasaOS**. Para la UI en aislamiento, **[CasaOS-UI/README.md](https://github.com/IceWhaleTech/CasaOS-UI/blob/main/README.md)**.
