Technical notes - MediaCreationTool.bat / MediaCreationTool.sh  
==============================================================

Both scripts are wrappers around Microsoft-hosted downloads. Neither bundles
Microsoft code, neither re-hosts a payload, neither downloads from third
parties. Every byte comes from a Microsoft domain.

```
MediaCreationTool.bat   windows only  - configures products.xml, runs the real MCT, then patches the media
MediaCreationTool.sh    bash (linux)  - resolves the same sources itself, downloads, verifies, patches
```


1. Sources
----------

Both scripts resolve a payload from one of two places.

### 1.1 Official ISO api (current release)

The same protocol used by Fido / mido:

| step | request |
|------|---------|
| 1 | `GET https://www.microsoft.com/en-us/software-download/<page>` - seeds cookies |
| 2 | `GET https://vlscppe.microsoft.com/tags?org_id=y6jn8c31&session_id=<uuid>` |
| 3 | `GET https://ov-df.microsoft.com/mdt.js?instanceId=560dc9f3-1aa5-4a2f-b63c-9e18f8d0e175&PageId=si&session_id=<uuid>` -> `w`, `rticks` |
| 4 | `GET https://ov-df.microsoft.com/?session_id=..&CustomerId=..&PageId=si&w=..&mdt=<epoch ms>&rticks=..` |
| 5 | `GET .../software-download-connector/api/getskuinformationbyproductedition?profile=606624d44113&productEditionId=<id>&SKU=undefined&Locale=en-US&sessionID=<uuid>` -> language + sku id list |
| 6 | `GET .../api/GetProductDownloadLinksBySku?profile=606624d44113&SKU=<sku>&Locale=en-US&sessionID=<uuid>` -> `ProductDownloadOptions[].Uri` |

Current entries (as of 2026.10):

| key | label | product edition id | page |
|-----|-------|--------------------|------|
| `official11` | Windows 11 26H2 build 26300.9457 | 3813 | `windows11` |
| `official10` | Windows 10 22H2 build 19045.2965 | 2618 | `windows10iso` |

The sku id is only valid for the `sessionID` that produced it, so the language
list and the download links must be requested in the same run.

The language list uses friendly names (`English`, `Spanish`,
`English (United Kingdom)`), not language codes. `MediaCreationTool.sh` maps
`en-us`, `es-es`, `pt-br`, `zh-cn`, ... to those names (`api_lang_name`), then
falls back to `en-us` when the requested language is not offered.

The returned uri is a signed, short lived link
(`?t=..&P1=<expiry>&P2=..&P3=..`) - download it right away, do not store it.

**Known limitation:** step 6 is guarded by Microsoft download protection
(Sentinel). From some networks / regions the answer is
`ErrorSettings.SentinelReject` - "Sentinel marked this request as rejected",
message code `715-123130`. This is IP based, it also happens with Fido from
the same host. Measured from one host in 2026.10: `official10` (Windows 10
22H2) completed and returned a live 5 GB iso, `official11` (Windows 11 26H2)
was rejected every time. The `.sh` prints the session id, retries, and then
falls back to the catalog esd (see 1.2), so the command still completes.

### 1.2 Microsoft catalog (esd)

The catalog is a `products.cab` (or `.xml`) published by Microsoft per
Windows version. It is extracted with `cabextract` and read with `python3`
(`xml.etree.ElementTree`), no other tooling.

```
products.cab  --cabextract-->  products.xml
<File>
  <FileName>            <LanguageCode>  <Language>  <Edition>
  <Architecture>        <Size>          <Sha1>      <FilePath>
</File>
```

`FilePath` is a full URL on `dl.delivery.mp.microsoft.com` or
`fg.ds.b1.download.windowsupdate.com` (plain HTTP). A HEAD request answers 200
and carries the same `Content-Length` as the published `Size`; `--dry-run`
reports the link as alive on that status, and after a real download the byte
count is compared with `Size` again. `IsRetailOnly` is ignored, the same way
the `.bat` unhides business editions.

Versions in `MediaCreationTool.sh` (`CATALOG_TABLE`):

| key | label |
|-----|-------|
| 1507 1511 1607 | Windows 10 - **cabs are on `wscont.apps.microsoft.com`, that host no longer resolves, these three versions cannot be downloaded** |
| 1703 1709 1803 1809 1903 1909 20H1 20H2 21H1 21H2 22H2 | Windows 10 |
| 11_21H2 11_22H2 11_23H2 | Windows 11 (x64 only) |

Selection rules in `catalog_resolve` (same spirit as the `.bat`):

* ARM entries are dropped (the `.bat` does the same).
* requested arch not present -> abort listing the available archs
* requested language not present -> same primary tag (e.g. `pt-br` -> `pt-pt`),
  else `en-us`, else abort
* requested edition not present -> `Professional`, else abort
* aliases: `Home`->`Core`, `Pro`->`Professional`, `Edu`->`Education`, ...

The `.bat` additionally patches the xml (unhide Enterprise / Education, insert
the business CSV rows for 1607 / 1703 / 1909 - 11_23H2, fix EULA urls, label
rewrites) before handing it to MCT. The `.sh` has no MCT to talk to, it reads
the catalog and downloads the chosen esd directly, so those patches are not
needed - but that also means no ARM64 and no AiO image.

**esd vs iso:** catalog files are `install.esd` (a compressed wim), not an
installer tree - there is no `boot/etfsboot.com` to rebuild a bootable iso
from. The `.sh` therefore downloads the esd as-is and keeps the extras next to
it; it does not attempt esd -> iso. Use `official11` / `official10` when a real
iso is required.


2. Download and verification
----------------------------

`download_payload` picks the first available downloader:

```
aria2c  (-c -x 8 -s 8, resume)   ->   curl (-C -)   ->   wget -c
```

* existing file with the expected size is reused, otherwise the download is
  resumed
* free space is checked against the published `Size` before starting
* after the transfer the size is compared again
* when the catalog published a `Sha1`, `verify_payload` checks it
  (`sha1sum` / `shasum` / `python3`) and fails the run on mismatch
* `--dry-run` stops after resolving + HEAD, nothing is written


3. Media extras
---------------

Presets 1 - 4 (both scripts) add files next to / inside the media:

| file | purpose |
|------|---------|
| `auto.cmd` | unattended in-place upgrade: picks an index from `install.esd`, sets `EditionID`, skips the windows 11 checks, applies the recommended setup options |
| `sources/PID.txt` | preselects the edition |
| `sources/EI.cfg` | suppresses the product key prompt (windows 11 consumer media) |
| `AutoUnattend.xml` | offline local account on windows 11 home (goes into `boot.wim`) |
| `$ISO$/` | copied to the root of the media (branding, `$OEM$`, tweaks) |
| `bypass11/` | optional skip tpm / secure boot toggles |

The `auto.cmd` body is identical in both scripts: the `.sh` embeds the very
template the `.bat` writes in `:generate_auto_cmd` (the `pushd "%~dp0" ...` up to
the `#:WIM_INFO:#` marker), only the generated header (`EDITION_SWITCH`,
`SKIP_11_SETUP_CHECKS`, `OPTIONS`) is computed per run.

Injection into the media:

* `.bat` - MCT creates the media, the script then writes the files onto it, or
  builds the iso itself with the embedded `MakeISO` (dir2iso) snippet
* `.sh` - `xorriso -indev <iso> -outdev <tmp> -boot_image any replay -map ...
  -commit -end` rewrites the iso in place while keeping the boot record; if
  `xorriso` is missing the extras stay in `media-extras/` next to the file
* `def` (or preset 5, *MCT Defaults* / *plain download*) adds nothing

Differences between the two:

* the `.bat` mounts `boot.wim` with `dism` and patches `winsetup.dll` (renames
  `Module_Init_HWRequirements` to `Module_Init_GatherDiskInfo`) to remove the
  windows 11 setup checks when booting from the media. The `.sh` does **not**
  touch `boot.wim` - that bypass stays windows-only
* the `.bat` puts `AutoUnattend.xml` inside `boot.wim`; the `.sh` maps it to the
  root of the iso (`/autounattend.xml`), which is also one of the answer file
  locations windows setup searches
* the `.sh` copies a local `bypass11/` folder (the repo's tpm / dynamic update
  toggles) into `media-extras/` when it exists next to the script; the `.bat`
  does not touch that folder


4. USB target
-------------

* `.bat` - MCT writes the stick, the script only chooses the preset
* `.sh` - lists removable devices with `lsblk`, asks for the device name twice
  (once to select, once to confirm destruction), checks that the stick is not
  smaller than the image, then `dd if=<iso> of=/dev/<dev> bs=4M conv=fsync`


5. The Exit option
------------------

Both menus gained a way out:

| | windows (`MediaCreationTool.bat`) | linux (`MediaCreationTool.sh`) |
|---|---|---|
| console menu | line `6      Exit      : quit the script ...` | `6      Exit      : quit the script` |
| gui dialog | `E&xit` appended to `PRESETS` (item 6, `Cancel` is item 7) | n/a (text menu) |
| keyboard | - | `6`, `q` or `Q` |
| handling | `if %PRE% equ 6 goto exitp` at the top of `:process`, before the self elevation, then `:exitp` prints ` EXITED ` and `exit /b` | `pick_preset` prints `bye` and `exit 0` |

`dP` (the default preset) is still `4` (*Select*), and the elevation re-parse
loop still only accepts presets 1 - 4, so Exit never triggers a UAC prompt.


6. Command line
---------------

`MediaCreationTool.bat` parses the script name and the arguments:

```
auto | iso | no_update | def | hide | <version> | <edition> | <lang> | <arch> | <key>
MediaCreationTool.bat 21H1 Education en-US x86 iso
auto 21H2 Pro MediaCreationTool.bat
```

`MediaCreationTool.sh` mirrors that:

```
./MediaCreationTool.sh [--dry-run] [auto|iso|usb|select] [def] [no_update]
                       [version] [edition] [lang] [arch] [key]
./MediaCreationTool.sh iso official11 en-US x64
./MediaCreationTool.sh auto 11_23H2 Professional en-US
./MediaCreationTool.sh --dry-run iso 1909
```

Version aliases accepted by the `.sh`: `1507 th1 1511 th2 1607 rs1 1703 rs2
1709 rs3 1803 rs4 1809 rs5 1903 19H1 1909 19H2 20H1 2004 20H2 2009 21H1 2104
21H2 2109 22H2 2210 11_21H2 11_22H2 11_23H2 2310 latest official11 official10
11 10`. Language codes are accepted in any case (`de-DE`, `es_es`).
`./MediaCreationTool.sh --help` prints the full usage.


7. Requirements
---------------

`MediaCreationTool.bat`: windows 7 - 11, powershell (2.0 works), MCT and the
script do the rest. No right click -> run as administrator needed.

`MediaCreationTool.sh`:

| tool | needed for |
|------|-----------|
| `bash` 4+ | script |
| `curl` | all http requests (required) |
| `python3` | catalog parsing, uuid, sha1 fallback |
| `cabextract` | reading `products.cab` |
| `aria2c` or `wget` | optional faster / resumable download |
| `xorriso` | optional, inject extras into the iso |
| `lsblk` + `dd` | usb preset |
| `sha1sum` / `shasum` | verification (python3 fallback exists) |

Example: `sudo apt install curl python3 cabextract xorriso aria2`


8. Development notes
--------------------

* `bash -n MediaCreationTool.sh` and `shellcheck -S warning MediaCreationTool.sh`
  are clean; the script runs with `set -u`
* prompt / status output goes to stderr, only data goes to stdout, so the
  functions can be used inside `$( )`
* the script can be sourced (`if [ "${BASH_SOURCE[0]:-$0}" = "$0" ]`) which
  makes `resolve_catalog`, `api_probe`, `verify_payload`, ... testable on their
  own
* catalog cabs are cached in `./.mct-catalog-<version>/`, an existing payload
  is reused instead of downloaded again
* no credentials, no telemetry, no download from anywhere but Microsoft
