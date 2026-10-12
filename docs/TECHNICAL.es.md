Notas técnicas - MediaCreationTool.bat / MediaCreationTool.sh  
=============================================================

Ambos scripts son wrappers sobre descargas alojadas por Microsoft. Ninguno
empaqueta código de Microsoft, ninguno re-aloja una imagen, ninguno descarga de
terceros. Cada byte viene de un dominio de Microsoft.

```
MediaCreationTool.bat   solo windows - configura products.xml, ejecuta el MCT real y parchea los medios
MediaCreationTool.sh    bash (linux) - resuelve las mismas fuentes él mismo, descarga, verifica, parchea
```


1. Fuentes
----------

Los dos scripts resuelven la imagen desde uno de dos orígenes.

### 1.1 Api oficial de iso (versión actual)

El mismo protocolo que usan Fido / mido:

| paso | petición |
|------|----------|
| 1 | `GET https://www.microsoft.com/en-us/software-download/<page>` - siembra cookies |
| 2 | `GET https://vlscppe.microsoft.com/tags?org_id=y6jn8c31&session_id=<uuid>` |
| 3 | `GET https://ov-df.microsoft.com/mdt.js?instanceId=560dc9f3-1aa5-4a2f-b63c-9e18f8d0e175&PageId=si&session_id=<uuid>` -> `w`, `rticks` |
| 4 | `GET https://ov-df.microsoft.com/?session_id=..&CustomerId=..&PageId=si&w=..&mdt=<epoch ms>&rticks=..` |
| 5 | `GET .../software-download-connector/api/getskuinformationbyproductedition?profile=606624d44113&productEditionId=<id>&SKU=undefined&Locale=en-US&sessionID=<uuid>` -> lista de idiomas + sku id |
| 6 | `GET .../api/GetProductDownloadLinksBySku?profile=606624d44113&SKU=<sku>&Locale=en-US&sessionID=<uuid>` -> `ProductDownloadOptions[].Uri` |

Entradas actuales (a 2026.10):

| clave | etiqueta | product edition id | página |
|-------|----------|--------------------|--------|
| `official11` | Windows 11 26H2 build 26300.9457 | 3813 | `windows11` |
| `official10` | Windows 10 22H2 build 19045.2965 | 2618 | `windows10iso` |

El sku id solo es válido para el `sessionID` que lo generó, así que la lista de
idiomas y los enlaces de descarga deben pedirse en la misma ejecución.

La lista de idiomas usa nombres legibles (`English`, `Spanish`,
`English (United Kingdom)`), no códigos de idioma. `MediaCreationTool.sh`
mapea `en-us`, `es-es`, `pt-br`, `zh-cn`, ... a esos nombres (`api_lang_name`) y
si no se ofrece el idioma pedido vuelve a `en-us`.

La uri devuelta es un enlace firmado y de vida corta
(`?t=..&P1=<caducidad>&P2=..&P3=..`) - descárgalo enseguida, no lo guardes.

**Limitación conocida:** el paso 6 está protegido por la descarga protegida de
Microsoft (Sentinel). Desde algunas redes / regiones la respuesta es
`ErrorSettings.SentinelReject` - "Sentinel marked this request as rejected",
código `715-123130`. Es por IP, también le pasa a Fido desde el mismo host.
Medido desde un host en 2026.10: `official10` (Windows 10 22H2) terminó y devolvió
un iso vivo de 5 GB, `official11` (Windows 11 26H2) fue rechazado siempre. El
`.sh` imprime el session id, reintenta y después vuelve al esd del catálogo
(ver 1.2), así que el comando termina igualmente.

### 1.2 Catálogo de Microsoft (esd)

El catálogo es un `products.cab` (o `.xml`) publicado por Microsoft por versión
de windows. Se extrae con `cabextract` y se lee con `python3`
(`xml.etree.ElementTree`), sin más herramientas.

```
products.cab  --cabextract-->  products.xml
<File>
  <FileName>            <LanguageCode>  <Language>  <Edition>
  <Architecture>        <Size>          <Sha1>      <FilePath>
</File>
```

`FilePath` es una URL completa en `dl.delivery.mp.microsoft.com` o
`fg.ds.b1.download.windowsupdate.com` (HTTP simple). Una petición HEAD
responde 200 y lleva el mismo `Content-Length` que el `Size` publicado;
`--dry-run` da el enlace por vivo con ese estado, y tras una descarga real la
cantidad de bytes se vuelve a comparar con `Size`. `IsRetailOnly` se ignora,
igual que el `.bat` desoculta las ediciones empresariales.

Versiones en `MediaCreationTool.sh` (`CATALOG_TABLE`):

| clave | etiqueta |
|-------|----------|
| 1507 1511 1607 | Windows 10 - **los cabs están en `wscont.apps.microsoft.com`, ese host ya no resuelve, estas tres versiones no se pueden descargar** |
| 1703 1709 1803 1809 1903 1909 20H1 20H2 21H1 21H2 22H2 | Windows 10 |
| 11_21H2 11_22H2 11_23H2 | Windows 11 (solo x64) |

Reglas de selección en `catalog_resolve` (mismo espíritu que el `.bat`):

* las entradas ARM se descartan (el `.bat` hace lo mismo)
* si la arquitectura pedida no está -> se aborta listando las disponibles
* si el idioma pedido no está -> misma etiqueta primaria (p. ej. `pt-br` ->
  `pt-pt`), si no `en-us`, si no se aborta
* si la edición pedida no está -> `Professional`, si no se aborta
* alias: `Home`->`Core`, `Pro`->`Professional`, `Edu`->`Education`, ...

El `.bat` además parchea el xml (desoculta Enterprise / Education, inserta las
filas CSV de negocio para 1607 / 1703 / 1909 - 11_23H2, corrige las urls de
EULA, reescribe etiquetas) antes de pasárselo a MCT. El `.sh` no tiene un MCT
con el que hablar, lee el catálogo y descarga el esd elegido directamente, así
que esos parches no hacen falta - pero tampoco hay imagen ARM64 ni AiO.

**esd vs iso:** los archivos del catálogo son `install.esd` (un wim comprimido),
no un árbol de instalación - no hay `boot/etfsboot.com` del que reconstruir un
iso arrancable. Por eso el `.sh` descarga el esd tal cual y deja los extras al
lado; no intenta convertir esd -> iso. Usa `official11` / `official10` cuando
haga falta un iso de verdad.


2. Descarga y verificación
--------------------------

`download_payload` elige el primer descargador disponible:

```
aria2c  (-c -x 8 -s 8, reanuda)   ->   curl (-C -)   ->   wget -c
```

* un archivo existente con el tamaño esperado se reutiliza, si no la descarga
  se reanuda
* antes de empezar se comprueba el espacio libre frente al `Size` publicado
* después de la transferencia el tamaño se vuelve a comparar
* cuando el catálogo publica un `Sha1`, `verify_payload` lo comprueba
  (`sha1sum` / `shasum` / `python3`) y falla si no coincide
* `--dry-run` se detiene tras resolver + HEAD, no escribe nada


3. Extras de los medios
-----------------------

Los preajustes 1 - 4 (en los dos scripts) añaden archivos junto a / dentro de
los medios:

| archivo | propósito |
|---------|-----------|
| `auto.cmd` | actualización in situ sin atender: elige un índice de `install.esd`, fija `EditionID`, salta las comprobaciones de windows 11, aplica las opciones de setup recomendadas |
| `sources/PID.txt` | preselecciona la edición |
| `sources/EI.cfg` | evita el aviso de clave de producto (medios consumer de windows 11) |
| `AutoUnattend.xml` | cuenta local sin conexión en windows 11 home (va dentro de `boot.wim`) |
| `$ISO$/` | se copia a la raíz de los medios (marca, `$OEM$`, ajustes) |
| `bypass11/` | conmutadores opcionales de omisión de tpm / secure boot |

El cuerpo de `auto.cmd` es idéntico en los dos scripts: el `.sh` incrusta la
propia plantilla que escribe el `.bat` en `:generate_auto_cmd` (desde
`pushd "%~dp0" ...` hasta el marcador `#:WIM_INFO:#`); solo la cabecera
generada (`EDITION_SWITCH`, `SKIP_11_SETUP_CHECKS`, `OPTIONS`) se calcula en
cada ejecución.

Inyección en los medios:

* `.bat` - MCT crea los medios y el script escribe los archivos encima, o crea
  el iso él mismo con el fragmento embebido `MakeISO` (dir2iso)
* `.sh` - `xorriso -indev <iso> -outdev <tmp> -boot_image any replay -map ...
  -commit -end` reescribe el iso conservando el registro de arranque; si falta
  `xorriso` los extras se quedan en `media-extras/` junto al archivo
* `def` (o preajuste 5, *MCT Defaults* / descarga sin cambios) no añade nada

Diferencias entre los dos:

* el `.bat` monta `boot.wim` con `dism` y parchea `winsetup.dll` (cambia
  `Module_Init_HWRequirements` por `Module_Init_GatherDiskInfo`) para quitar
  las comprobaciones de windows 11 al arrancar desde los medios. El `.sh` **no**
  toca `boot.wim` - esa evasión sigue siendo solo de windows
* el `.bat` pone `AutoUnattend.xml` dentro de `boot.wim`; el `.sh` lo mapea a
  la raíz del iso (`/autounattend.xml`), que también es una de las ubicaciones
  de archivo de respuesta que busca el setup de windows
* el `.sh` copia una carpeta local `bypass11/` (los conmutadores de tpm /
  actualización dinámica del repo) dentro de `media-extras/` si existe junto al
  script; el `.bat` no toca esa carpeta


4. Destino usb
--------------

* `.bat` - MCT escribe el stick, el script solo elige el preajuste
* `.sh` - lista los dispositivos extraíbles con `lsblk`, pide el nombre del
  dispositivo dos veces (una para elegir, otra para confirmar la destrucción),
  comprueba que el stick no sea menor que la imagen y luego
  `dd if=<iso> of=/dev/<dev> bs=4M conv=fsync`


5. La opción Exit
-----------------

Los dos menús ganaron una salida:

| | windows (`MediaCreationTool.bat`) | linux (`MediaCreationTool.sh`) |
|---|---|---|
| menú de consola | línea `6      Exit      : quit the script ...` | `6      Exit      : quit the script` |
| diálogo gui | `E&xit` añadido a `PRESETS` (elemento 6, `Cancel` es el 7) | n/a (menú de texto) |
| teclado | - | `6`, `q` o `Q` |
| manejo | `if %PRE% equ 6 goto exitp` al principio de `:process`, antes de la elevación propia, y `:exitp` imprime ` EXITED ` y `exit /b` | `pick_preset` imprime `bye` y `exit 0` |

`dP` (el preajuste por defecto) sigue siendo `4` (*Select*), y el bucle de
reanálisis para la elevación sigue aceptando solo los preajustes 1 - 4, así que
Exit nunca dispara un aviso de UAC.


6. Línea de comandos
--------------------

`MediaCreationTool.bat` analiza el nombre del script y los argumentos:

```
auto | iso | no_update | def | hide | <version> | <edition> | <lang> | <arch> | <key>
MediaCreationTool.bat 21H1 Education en-US x86 iso
auto 21H2 Pro MediaCreationTool.bat
```

`MediaCreationTool.sh` replica eso:

```
./MediaCreationTool.sh [--dry-run] [auto|iso|usb|select] [def] [no_update]
                       [version] [edition] [lang] [arch] [key]
./MediaCreationTool.sh iso official11 en-US x64
./MediaCreationTool.sh auto 11_23H2 Professional en-US
./MediaCreationTool.sh --dry-run iso 1909
```

Alias de versión que acepta el `.sh`: `1507 th1 1511 th2 1607 rs1 1703 rs2
1709 rs3 1803 rs4 1809 rs5 1903 19H1 1909 19H2 20H1 2004 20H2 2009 21H1 2104
21H2 2109 22H2 2210 11_21H2 11_22H2 11_23H2 2310 latest official11 official10
11 10`. Los códigos de idioma se aceptan en cualquier mayúscula (`de-DE`,
`es_es`). `./MediaCreationTool.sh --help` imprime el uso completo.


7. Requisitos
-------------

`MediaCreationTool.bat`: windows 7 - 11, powershell (funciona con 2.0), el MCT
y el script hacen el resto. No hace falta clic derecho -> Ejecutar como
administrador.

`MediaCreationTool.sh`:

| herramienta | para qué |
|-------------|----------|
| `bash` 4+ | script |
| `curl` | todas las peticiones http (obligatorio) |
| `python3` | leer el catálogo, uuid, respaldo de sha1 |
| `cabextract` | leer `products.cab` |
| `aria2c` o `wget` | descarga opcional más rápida / reanudable |
| `xorriso` | opcional, inyectar extras en el iso |
| `lsblk` + `dd` | preajuste usb |
| `sha1sum` / `shasum` | verificación (existe respaldo con python3) |

Ejemplo: `sudo apt install curl python3 cabextract xorriso aria2`


8. Notas de desarrollo
----------------------

* `bash -n MediaCreationTool.sh` y `shellcheck -S warning MediaCreationTool.sh`
  están limpios; el script corre con `set -u`
* la salida de prompt / estado va a stderr, solo los datos van a stdout, así
  que las funciones se pueden usar dentro de `$( )`
* el script se puede cargar con `source` (`if [ "${BASH_SOURCE[0]:-$0}" =
  "$0" ]`), lo que permite probar `resolve_catalog`, `api_probe`,
  `verify_payload`, ... por separado
* los cabs del catálogo se cachean en `./.mct-catalog-<version>/`, una imagen
  ya descargada se reutiliza en lugar de volver a bajarla
* sin credenciales, sin telemetría, sin descargar de ningún sitio que no sea
  Microsoft
