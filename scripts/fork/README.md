# Scripts del fork (UI → instalación corriente)

Flujo simple:

1. En tu máquina (o CI): en el repo **CasaOS-UI**, `pnpm install && pnpm run build`.
2. Lleva la carpeta generada  
   `CasaOS-UI/build/sysroot/var/lib/casaos/www/`  
   al servidor (scp, rsync, USB, etc.), **o** haz `git pull` del fork y compila allí.
3. En el servidor con CasaOS ya instalado:

   ```bash
   cd /ruta/al/clon/CasaOS
   sudo bash scripts/fork/apply-ui-build.sh /ruta/al/www-compilado
   ```

   Si el build está en la ruta por defecto (`../CasaOS-UI/build/.../www` respecto a **CasaOS**):

   ```bash
   sudo CASA_UI_BUILD=/home/tu/CasaOS-UI/build/sysroot/var/lib/casaos/www bash scripts/fork/apply-ui-build.sh
   ```

## Instalar oficial y parchear UI en un solo paso

En un sistema **sin** CasaOS previo (o si quieres reinstalar base oficial y luego poner la UI del fork):

```bash
sudo bash scripts/fork/install-official-then-apply-ui.sh /ruta/al/www
```

## Advertencia: Ajustes → Actualizar

En la interfaz, **Configuración → Actualizar** usa el canal de **IceWhale**. Eso puede **sustituir** tu UI (y el paquete `casaos`) por la versión oficial y **deshacer el fork** en el navegador.

- Para actualizar el fork: **git pull** + volver a **build** + `apply-ui-build.sh`.
- Para volver al upstream a propósito: usa los comandos oficiales del README (`get.casaos.io` / `update`).

## Git: commit, push y aplicar en el servidor

1. **En tu máquina:** haz **commit y push** de los cambios del fork (código, scripts, docs). Lo habitual es **no** versionar la carpeta `www` compilada (artefacto generado; suele estar en `.gitignore`). Si prefieres subir el build al repo, es posible, pero aumenta el tamaño del clon.
2. **En la máquina con CasaOS instalado:** `git pull` del fork (repos **CasaOS** y **CasaOS-UI** si trabajas con ambos en el mismo host), luego en **CasaOS-UI** ejecuta `pnpm install && pnpm run build`, y finalmente `apply-ui-build.sh` apuntando al `www` generado.

Alternativa sin compilar en el servidor: generas el `www` en tu PC, lo copias con `rsync`/`scp` al destino y ejecutas el script con esa ruta.

### ¿Hace falta `git pull` antes de `curl … | bash` al `.sh`?

- **Para tener el script:** no es obligatorio. Puedes descargar el script con `curl` desde la URL *raw* de GitHub/GitLab **sin** clonar el repo.
- **Para aplicar tu UI:** el script **solo** copia una carpeta `www` que **ya debe existir** (con `index.html`). Ese contenido **no** viene del `curl` al `.sh`. Lo obtienes con `git pull` + build en el servidor, o llevando el `www` desde otra máquina.

Orden lógico en destino: tener el `www` listo → ejecutar `apply-ui-build.sh` (local tras pull, o pasando la ruta si copiaste el build).

## Comandos oficiales (referencia)

Siguen documentados en el [README principal](../../README.md) de este repo: instalación y actualización **originales** IceWhale.
