# Fork: UI sobre instalación oficial

Este fork **no sustituye** el paquete `casaos` de IceWhale por otro instalador propio. Lo que instalas en el sistema es **CasaOS oficial**; aquí aportas la **interfaz web** (archivos estáticos en `/var/lib/casaos/www`). El modo “como en local en el puerto 4080” es el **mismo build** de `CasaOS-UI`, aplicado al host en lugar del dev server.

## Comprobar que CasaOS está instalado

En el host:

```bash
which casaos    # ej. /usr/bin/casaos
casaos -v
```

Si no hay binario, instala la base **oficial** primero:

```bash
curl -fsSL https://get.casaos.io | sudo bash
```

## Layout de directorios (recomendado)

Clona tu fork en dos repos **hermanos** (misma carpeta padre):

```text
~/src/
  CasaOS/      ← este repo (scripts en scripts/fork/)
  CasaOS-UI/   ← repo de la interfaz
```

Si `CasaOS-UI` está en otra ruta:

```bash
export CASA_UI_ROOT=/ruta/absoluta/a/CasaOS-UI
bash scripts/fork/install-fork-ui.sh
```

## Un solo script: compilar y aplicar la UI

Desde el clon de **CasaOS** (sin `sudo` al principio; `sudo` solo al copiar a `/var/lib/casaos/www`):

```bash
cd ~/src/CasaOS
bash scripts/fork/install-fork-ui.sh
```

Hace: `pnpm install` + `pnpm run build` en **CasaOS-UI** y luego ejecuta **`apply-ui-build.sh`** con `sudo` (copia con backup a `/var/lib/casaos/www`).

Solo compilar, sin tocar el sistema:

```bash
bash scripts/fork/install-fork-ui.sh --build-only
```

Si ya tienes el `www` generado y solo quieres copiarlo:

```bash
sudo bash scripts/fork/apply-ui-build.sh /ruta/a/CasaOS-UI/build/sysroot/var/lib/casaos/www
sudo systemctl restart casaos-gateway
```

### Instalar base oficial y luego el fork (máquina casi vacía)

Si **no** hay `casaos` aún, usa (todo con `sudo`; instala IceWhale y aplica el `www` que indiques):

```bash
sudo bash scripts/fork/install-official-then-apply-ui.sh /ruta/al/www
```

Si **sí** hay `casaos`, ese script solo aplica la UI (igual que `apply-ui-build.sh`).

## ¿Puedo borrar el directorio del repo clonado después?

**Sí**, para el **funcionamiento diario** de CasaOS no hace falta dejar el clon en el disco: los archivos ya están en `/var/lib/casaos/www`.

Conviene **mantener** un clon (o volver a `git clone`) cuando quieras **actualizar el fork** (`git pull` → `install-fork-ui.sh` de nuevo). Si borras el clon, en la próxima actualización vuelves a clonar o copias el script `apply-ui-build.sh` y una carpeta `www` ya compilada.

## Reinstalación limpia (base oficial) conservando datos

1. **Backup** (obligatorio):

   ```bash
   sudo tar -czvf "casaos-backup-$(date +%F).tar.gz" /var/lib/casaos /etc/casaos
   ```

2. **Desinstalar** (ver [README principal](../../README.md)):

   ```bash
   sudo casaos-uninstall
   ```

   Para **no** perder apps Docker ni datos: responde **`n`** a eliminar todos los contenedores y **`n`** a borrar AppData en `/DATA/AppData` si te interesa conservarlos.

3. **Instalar de nuevo** la base oficial:

   ```bash
   curl -fsSL https://get.casaos.io | sudo bash
   ```

4. **Aplicar la UI del fork** (clon con `CasaOS` + `CasaOS-UI` como arriba):

   ```bash
   cd /ruta/al/CasaOS
   bash scripts/fork/install-fork-ui.sh
   ```

5. **Volver al upstream** (paquetes + UI oficial), sin reinstalar a mano:

   ```bash
   curl -fsSL https://get.casaos.io/update | sudo bash
   ```

   Luego puedes volver a ejecutar `install-fork-ui.sh` si quieres otra vez la UI del fork.

**Nota:** una reinstalación limpia **no corrige** iframes con URL `http://localhost:…` vistos desde **otro** equipo; usa **hostname o IP del servidor** en la Web UI de cada app.

## Advertencia: Ajustes → Actualizar

En la interfaz, **Configuración → Actualizar** usa el canal **IceWhale** y puede **sustituir** tu UI por la oficial. Para refrescar el fork: `git pull`, `install-fork-ui.sh` (o build manual + `apply-ui-build.sh`).

## Git en el servidor y `curl` al `.sh`

- Para **actualizar fuentes**: `git pull` en **CasaOS** y **CasaOS-UI**.
- Puedes descargar solo un `.sh` con `curl` desde la URL *raw* de GitHub **sin** clonar, pero el **`www`** compilado no viene en ese download; hace falta build local o copiar la carpeta generada.

## Comandos oficiales

Instalación, actualización y desinstalación “stock”: [README principal](../../README.md).
