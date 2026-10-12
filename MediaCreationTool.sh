#!/usr/bin/env bash
# ============================================================================
#  Universal MediaCreationTool wrapper - Linux / macOS port
#  Same idea as MediaCreationTool.bat: only Microsoft-hosted source links,
#  no third party tools, script just configures the download and media extras.
#
#  Sources
#    - official : Microsoft software-download connector api (current iso)
#    - catalog  : Microsoft products.cab -> products.xml -> esd (1507 - 11 23H2)
#
#  Changelog: 2026.10.08 first linux release
# ============================================================================
set -u

MCT_SH_VERSION="2026.10.08"
MCT_SH_NAME="${0##*/}"

# --- Microsoft official iso api (same protocol as Fido / mido) ---------------
ORG_ID="y6jn8c31"
INSTANCE_ID="560dc9f3-1aa5-4a2f-b63c-9e18f8d0e175"
PROFILE_ID="606624d44113"
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
API_RETRY=3

# --- colors -------------------------------------------------------------------
if [ -t 1 ]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'
  C_GRAY=$'\033[90m'; C_RED=$'\033[31m'; C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'; C_MAGENTA=$'\033[35m'
  C_CYAN=$'\033[36m'; C_WHITE=$'\033[37m'
else
  C_RESET=""; C_BOLD=""; C_GRAY=""; C_RED=""; C_GREEN=""; C_YELLOW=""
  C_BLUE=""; C_MAGENTA=""; C_CYAN=""; C_WHITE=""
fi

# prompt / status output goes to stderr so command substitutions stay clean
say()   { printf '%s\n' "$*"; }
info()  { printf '%s %s %s\n' "$C_GRAY" "$*" "$C_RESET" >&2; }
ok()    { printf '%s DONE %s %s\n' "$C_GREEN" "$C_RESET" "$*" >&2; }
warn()  { printf '%s WARNING %s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
fail()  { printf '%s ERROR %s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
die()   { fail "$*"; exit 1; }
ask()   { printf '%s ? %s %s ' "$C_CYAN" "$*" "$C_RESET" >&2; read -r MCT_REPLY || MCT_REPLY=""; printf '%s' "$MCT_REPLY"; }

# --- version tables -----------------------------------------------------------
# catalog: key|label|build|catalog url
CATALOG_TABLE=(
  "1507|Windows 10 1507|10240|https://wscont.apps.microsoft.com/winstore/OSUpgradeNotification/MediaCreationTool/prod/Products09232015_2.xml"
  "1511|Windows 10 1511|10586|https://wscont.apps.microsoft.com/winstore/OSUpgradeNotification/MediaCreationTool/prod/Products05242016.xml"
  "1607|Windows 10 1607|14393|https://wscont.apps.microsoft.com/winstore/OSUpgradeNotification/MediaCreationTool/prod/Products_20170116.cab"
  "1703|Windows 10 1703|15063|https://download.microsoft.com/download/9/5/4/954415FD-D9D7-4E1F-8161-41B3A4E03D5E/products_20170317.cab"
  "1709|Windows 10 1709|16299|https://download.microsoft.com/download/3/2/3/323D0F94-95D2-47DE-BB83-1D4AC3331190/products_20180105.cab"
  "1803|Windows 10 1803|17134|https://download.microsoft.com/download/5/C/B/5CB83D2A-2D7E-4129-9AFE-353F8459AA8B/products_20180705.cab"
  "1809|Windows 10 1809|17763|https://download.microsoft.com/download/8/E/8/8E852CBF-0BCC-454E-BDF5-60443569617C/products_20190314.cab"
  "1903|Windows 10 1903|18362|https://download.microsoft.com/download/4/e/4/4e491657-24c8-4b7d-a8c2-b7e4d28670db/products_20190912.cab"
  "1909|Windows 10 1909|18363|https://download.microsoft.com/download/8/2/b/82b12fa5-cab6-4d37-8167-16630c6151eb/products_20200116.cab"
  "20H1|Windows 10 2004|19041|https://download.microsoft.com/download/7/4/4/744ccd60-3203-4eea-bfa2-4d04e18a1552/products.cab"
  "20H2|Windows 10 20H2|19042|https://download.microsoft.com/download/4/3/0/430e9adb-cf08-4b68-9032-eafca8378d42/products_20201119.cab"
  "21H1|Windows 10 21H1|19043|https://download.microsoft.com/download/8/3/e/83e5badb-90bd-45c0-b868-28ada88230a0/products_win10_20211029.cab"
  "21H2|Windows 10 21H2|19044|https://download.microsoft.com/download/3/9/6/396ae429-afb2-49da-81d8-c16c6782d082/products_Win10_20211115.cab"
  "22H2|Windows 10 22H2|19045|https://download.microsoft.com/download/3/c/9/3c959fca-d288-46aa-b578-2a6c6c33137a/products_win10_20230510.cab.cab"
  "11_21H2|Windows 11 21H2|22000|https://download.microsoft.com/download/1/b/4/1b4e06e2-767a-4c9a-9899-230fe94ba530/products_Win11_20211115.cab"
  "11_22H2|Windows 11 22H2|22621|https://download.microsoft.com/download/b/1/9/b19bd7fd-78c4-4f88-8c40-3e52aee143c2/products_win11_20230510.cab.cab"
  "11_23H2|Windows 11 23H2|22631|https://download.microsoft.com/download/6/2/b/62b47bc5-1b28-4bfa-9422-e7a098d326d4/products_win11_20231208.cab"
)

# official: key|label|product edition id|download page|catalog fallback key
OFFICIAL_TABLE=(
  "official11|Windows 11 26H2 (official iso)|3813|windows11|11_23H2"
  "official10|Windows 10 22H2 (official iso)|2618|windows10iso|22H2"
)

# same generic keys as MediaCreationTool.bat, for staged install.esd editions only
KEY_TABLE="
V3WVW-N2PV2-CGWC3-34QGF-VMJ2C.Cloud=NH9J3-68WK7-6FB93-4K3DF-DJ4F6.CloudN
YTMG3-N6DKC-DKB77-7M9GH-8HVX7.Core=4CPRK-NM3K3-X6XXQ-RXX86-WXCHW.CoreN
BT79Q-G7N6G-PGBYW-4YWX6-6F4BT.CoreSingleLanguage=N2434-X9D7W-8PF6X-8DV9T-8TYMD.CoreCountrySpecific
VK7JG-NPHTM-C97JM-9MPGT-3V66T.Professional=2B87N-8KFHP-DKV6R-Y2C8J-PKCKT.ProfessionalN
8PTT6-RNW4C-6V7J2-C2D3X-MHBPB.ProfessionalEducation=GJTYN-HDMQY-FRR76-HVGC7-QPF8P.ProfessionalEducationN
DXG7C-N36C4-C4HTG-X4T3X-2YV77.ProfessionalWorkstation=WYPNQ-8C467-V2W6J-TX4WX-WT2RQ.ProfessionalWorkstationN
YNMGQ-8RYV3-4PGQ3-C8XTP-7CFBY.Education=84NGF-MHBT6-FXBX8-QWJK7-DRR8H.EducationN
NPPR9-FWDCX-D2C8J-H872K-2YT43.Enterprise=DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4.EnterpriseN
"

EDITION_LIST="Professional Core Education Enterprise ProfessionalN CoreN EducationN EnterpriseN ProfessionalEducation ProfessionalWorkstation ProfessionalEducationN ProfessionalWorkstationN Cloud CloudN CoreSingleLanguage CoreCountrySpecific"
OPTIONS_OPTS="/Compat IgnoreWarning /MigrateDrivers All /ResizeRecoveryPartition Disable /ShowOOBE None /Telemetry Disable /CompactOS Disable"

PRESET=""; MCT_VER=""; EDITION=""; LANGCODE=""; ARCH=""; KEY=""
DEF=""; NO_UPDATE=""; DRY_RUN=0; USB_TARGET=""; PAYLOAD_FILE=""
PAYLOAD_URL=""; PAYLOAD_NAME=""; PAYLOAD_SIZE=""; PAYLOAD_SHA1=""
PAYLOAD_KIND=""; PAYLOAD_LABEL=""

# ----------------------------------------------------------------------------- usage
usage() {
  cat <<USAGE
$MCT_SH_NAME $MCT_SH_VERSION - universal MediaCreationTool wrapper for linux

usage: ./$MCT_SH_NAME [options] [arguments]

options:
  -h, --help        this help
  --dry-run         resolve the download link only, do not download

presets (argument or menu item):
  auto              build the windows upgrade kit (auto.cmd + PID.txt + EI.cfg)
  iso               download the iso / esd in the current folder
  usb               download the image and write it to a usb stick
  select            pick version, edition, language, arch and target
  def               default, untouched media (no extra files added)
  no_update         do not use dynamic update (same as the bat)

versions: 1507 1511 1607 1703 1709 1803 1809 1903 1909 20H1 20H2 21H1 21H2
          22H2 11_21H2 11_22H2 11_23H2   (esd from the microsoft catalog)
          official11 official10          (iso from the microsoft iso api)

media:    <edition> <langcode> <arch>   example:
          ./$MCT_SH_NAME iso 21H1 Education en-US x64

examples:
  ./$MCT_SH_NAME iso official11
  ./$MCT_SH_NAME auto 11_23H2 Professional en-US
  ./$MCT_SH_NAME --dry-run usb select 22H2
USAGE
  exit 0
}

# ----------------------------------------------------------------------------- helpers
need() { command -v "$1" >/dev/null 2>&1; }

check_deps() {
  local missing=""
  need curl || missing="$missing curl"
  [ -z "$missing" ] && return 0
  die "missing required tools:$missing - install them first (example: sudo apt install$missing)"
}

now_ms() {
  local t
  t=$(date +%s%3N 2>/dev/null) || t=""
  case "$t" in (*[!0-9]*|"") echo $(( $(date +%s) * 1000 )) ;; (*) printf '%s' "$t" ;; esac
}

new_guid() {
  if [ -r /proc/sys/kernel/random/uuid ]; then cat /proc/sys/kernel/random/uuid
  elif need uuidgen; then uuidgen | tr 'A-Z' 'a-z'
  elif need python3; then python3 -c 'import uuid;print(uuid.uuid4())'
  else die "no uuid source (need python3 or uuidgen)"; fi
}

human() {
  local b=$1 i=0 u=(B KB MB GB TB)
  while [ "$b" -ge 1024 ] && [ "$i" -lt 4 ]; do b=$((b/1024)); i=$((i+1)); done
  printf '%s %s' "$b" "${u[$i]}"
}

detect_lang() {
  local l="${LC_ALL:-${LC_MESSAGES:-${LANG:-en_US.UTF-8}}}"
  l="${l%%.*}"; l="${l%%@*}"
  printf '%s' "${l/_/-}" | tr 'A-Z' 'a-z'
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo x64 ;;
    i?86)         echo x86 ;;
    *)            echo x64 ;;
  esac
}

tool_get() {
  # tool_get <url> <dest> - aria2c, then curl, then wget (all support resume)
  local url=$1 dest=$2 tmp="$2.dl"
  if need aria2c; then
    if aria2c -c -x 8 -s 8 --console-log-level=warn --summary-interval=10 \
        --file-allocation=none -d "$(dirname "$dest")" -o "$(basename "$tmp")" "$url" 1>&2; then
      mv -f "$tmp" "$dest"; return 0
    fi
  fi
  if need curl; then
    if curl -L --fail --retry 3 --retry-delay 2 -C - -o "$tmp" "$url"; then
      mv -f "$tmp" "$dest"; return 0
    fi
  fi
  if need wget; then
    if wget -c -O "$tmp" "$url"; then mv -f "$tmp" "$dest"; return 0; fi
  fi
  return 1
}

http_head() { curl -sSI -m 45 -L "$1" 2>/dev/null | tr -d '\r'; }

http_ok() {
  case "$(http_head "$1")" in
    "HTTP/"*" 200"*|"HTTP/"*" 206"*) return 0 ;;
    *) return 1 ;;
  esac
}

http_size() { http_head "$1" | awk 'tolower($1)=="content-length:"{print $2; exit}'; }

file_size() { stat -c%s "$1" 2>/dev/null || stat -f%z "$1" 2>/dev/null || echo 0; }

sha1_of() {
  if need sha1sum; then sha1sum "$1" | cut -d" " -f1
  elif need shasum; then shasum -a 1 "$1" | cut -d" " -f1
  elif need python3; then python3 -c "import hashlib,sys;print(hashlib.sha1(open(sys.argv[1],'rb').read()).hexdigest())" "$1"
  else die "no sha1 tool (need sha1sum, shasum or python3)"; fi
}

# ----------------------------------------------------------------------------- catalog
catalog_file() {
  # catalog_file <version key> -> prints products.xml path (messages on stderr)
  local key=$1 url="" label="" build="" cabname="" out="$PWD/.mct-catalog-$1" entry
  for entry in "${CATALOG_TABLE[@]}"; do
    IFS='|' read -r e_key e_label e_build e_url <<< "$entry"
    if [ "$e_key" = "$key" ]; then url=$e_url; label=$e_label; build=$e_build; fi
  done
  [ -n "$url" ] || die "unknown version: $key"
  mkdir -p "$out" || die "cannot create $out"
  cabname="$out/$(basename "$url")"
  info "catalog: $label build $build"
  info "$url"
  if [ ! -s "$cabname" ]; then
    tool_get "$url" "$cabname" ||
      die "could not download the microsoft catalog - host for this version was retired"
  fi
  if [ "${url##*.}" = "cab" ]; then
    need cabextract || die "cabextract is required to read the microsoft catalog (example: sudo apt install cabextract)"
    cabextract -q -d "$out" "$cabname" >/dev/null 2>&1 ||
      die "cabextract failed on $cabname"
  else
    cp -f "$cabname" "$out/products.xml"
  fi
  [ -s "$out/products.xml" ] || die "products.xml not found in $cabname"
  printf '%s' "$out/products.xml"
}

catalog_resolve() {
  # catalog_resolve <xml> <edition> <langcode> <arch>
  # prints: url|size|sha1|filename|edition|lang|arch
  need python3 || die "python3 is required to read the microsoft catalog"
  python3 - "$1" "$2" "$3" "$4" <<'PY'
import sys, xml.etree.ElementTree as ET
path, want_ed, want_lang, want_arch = sys.argv[1:5]
root = ET.parse(path).getroot()

def text(el, tag):
    n = el.find(tag)
    return (n.text or "").strip() if n is not None and n.text else ""

entries = []
for f in root.findall(".//File"):
    arch = text(f, "Architecture")
    if arch.upper().startswith("ARM"):            # arm not supported (same as the bat)
        continue
    lang = text(f, "LanguageCode")
    if not lang or lang == "default":
        continue
    url = text(f, "FilePath")
    if not url:
        continue
    entries.append(dict(ed=text(f, "Edition"), lang=lang, arch=arch, url=url,
                        size=text(f, "Size"), sha1=text(f, "Sha1"),
                        name=text(f, "FileName")))
if not entries:
    sys.exit("catalog has no downloadable files")

archs = sorted({e["arch"] for e in entries})
if want_arch not in archs:
    sys.exit("architecture %s not available, available: %s" % (want_arch, ", ".join(archs)))

langs = sorted({e["lang"] for e in entries if e["arch"] == want_arch})
if want_lang not in langs:
    same_tag = [l for l in langs if l.split("-")[0] == want_lang.split("-")[0]]
    if same_tag:
        want_lang = same_tag[0]
    elif "en-us" in langs:
        print("  language %s not available for %s, using en-us" % (want_lang, want_arch),
              file=sys.stderr)
        want_lang = "en-us"
    else:
        sys.exit("language %s not available for %s, available: %s"
                 % (want_lang, want_arch, ", ".join(langs)))

same = [e for e in entries if e["lang"] == want_lang and e["arch"] == want_arch]
eds = sorted({e["ed"] for e in same})
alias = {"Home": "Core", "HomeN": "CoreN", "Pro": "Professional", "ProN": "ProfessionalN",
         "Edu": "Education", "EduN": "EducationN"}
want_ed = alias.get(want_ed, want_ed)
if want_ed not in eds:
    if "Professional" in eds:                       # bat default
        print("  edition %s not available, using Professional" % want_ed, file=sys.stderr)
        want_ed = "Professional"
    else:
        sys.exit("edition %s not available, available: %s" % (want_ed, ", ".join(eds)))

pick = [e for e in same if e["ed"] == want_ed][0]
print("|".join([pick["url"], pick["size"], pick["sha1"], pick["name"],
                pick["ed"], pick["lang"], pick["arch"]]))
PY
}

# ----------------------------------------------------------------------------- official iso api
api_probe() {
  # api_probe <page> <product edition id>
  # does the whole whitelisting dance and the sku request, sets:
  #   API_SESSION, API_LANGS (lang|localized|sku id, one per line)
  local page=$1 eid=$2 session jar jsonf body w rticks mdt attempt err
  session=$(new_guid)
  jar=$(mktemp /tmp/mct-cookies.XXXXXX)
  jsonf=$(mktemp /tmp/mct-sku.XXXXXX)

  # 1 - the download page (seeds cookies)
  curl -sS -m 45 -A "$UA" -c "$jar" -b "$jar" -o /dev/null \
    "https://www.microsoft.com/en-us/software-download/$page" || true
  # 2 - tag whitelist
  curl -sS -m 45 -A "$UA" -c "$jar" -b "$jar" -o /dev/null \
    "https://vlscppe.microsoft.com/tags?org_id=$ORG_ID&session_id=$session" || true
  # 3 - anti bot challenge
  body=$(curl -sS -m 45 -A "$UA" -c "$jar" -b "$jar" \
    "https://ov-df.microsoft.com/mdt.js?instanceId=$INSTANCE_ID&PageId=si&session_id=$session" 2>/dev/null || true)
  w=$(printf '%s' "$body" | grep -oE '[?&]w=[A-F0-9]+' | head -1 | cut -d= -f2)
  rticks=$(printf '%s' "$body" | grep -oE 'rticks=\"\+?[0-9]+' | head -1 | grep -oE '[0-9]+')
  if [ -z "$w" ] || [ -z "$rticks" ]; then
    rm -f "$jar" "$jsonf"
    die "could not retrieve ov-df data (microsoft download protection) - try again later"
  fi
  # 4 - reply with session id, epoch and the challenge answers
  mdt=$(now_ms)
  curl -sS -m 45 -A "$UA" -c "$jar" -b "$jar" -o /dev/null --max-redirs 0 \
    "https://ov-df.microsoft.com/?session_id=$session&CustomerId=$INSTANCE_ID&PageId=si&w=$w&mdt=$mdt&rticks=$rticks" || true
  # 5 - sku / language list, may require a few attempts
  attempt=0
  while :; do
    curl -sS -m 45 -A "$UA" -c "$jar" -b "$jar" \
      -H 'Accept: application/json, text/javascript, */*; q=0.01' \
      -H 'Accept-Language: en-US,en;q=0.9' \
      -H 'X-Requested-With: XMLHttpRequest' \
      -H "Referer: https://www.microsoft.com/en-us/software-download/$page" \
      -o "$jsonf" \
      "https://www.microsoft.com/software-download-connector/api/getskuinformationbyproductedition?profile=$PROFILE_ID&productEditionId=$eid&SKU=undefined&friendlyFileName=undefined&Locale=en-US&sessionID=$session" || true
    grep -q '"Skus"' "$jsonf" 2>/dev/null && break
    attempt=$((attempt+1))
    if [ "$attempt" -ge "$API_RETRY" ]; then
      err=$(sed -n 's/.*"Value":"\([^"]*\)".*/\1/p' "$jsonf" | head -1)
      rm -f "$jar" "$jsonf"
      die "microsoft refused the language request: ${err:-unknown error} (session $session)"
    fi
    sleep 2
  done
  rm -f "$jar"

  API_LANGS=$(python3 - "$jsonf" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
for s in d.get("Skus") or []:
    if not s.get("Id"):
        continue
    print("%s|%s|%s" % (s.get("Language", "") or "",
                        s.get("LocalizedLanguage", "") or s.get("Language", ""),
                        s.get("Id", "")))
PY
)
  rm -f "$jsonf"
  [ -n "$API_LANGS" ] || die "microsoft returned no languages (session $session)"
  API_SESSION=$session
}

api_links() {
  # api_links <page> <session> <sku id> -> one iso url per line, empty on refusal
  local page=$1 session=$2 sku=$3 jar jsonf attempt err out
  jar=$(mktemp /tmp/mct-cookies.XXXXXX)
  jsonf=$(mktemp /tmp/mct-lnk.XXXXXX)
  attempt=0
  while :; do
    curl -sS -m 60 -A "$UA" -c "$jar" -b "$jar" \
      -H 'Accept: application/json, text/javascript, */*; q=0.01' \
      -H 'Accept-Language: en-US,en;q=0.9' \
      -H 'X-Requested-With: XMLHttpRequest' \
      -H "Referer: https://www.microsoft.com/en-us/software-download/$page" \
      -o "$jsonf" \
      "https://www.microsoft.com/software-download-connector/api/GetProductDownloadLinksBySku?profile=$PROFILE_ID&productEditionId=undefined&SKU=$sku&friendlyFileName=undefined&Locale=en-US&sessionID=$session" || true
    grep -q '"ProductDownloadOptions"' "$jsonf" 2>/dev/null && break
    err=$(sed -n 's/.*"Value":"\([^"]*\)".*/\1/p' "$jsonf" | head -1)
    attempt=$((attempt+1))
    if [ "$attempt" -ge "$API_RETRY" ]; then
      rm -f "$jar" "$jsonf"
      fail "microsoft sentinel rejected the iso request: ${err:-no link returned}"
      fail "session id $session - message code 715-123130"
      fail "your ip may be rate limited or region blocked, try again later"
      fail "meanwhile the catalog versions (esd) always work"
      return 1
    fi
    sleep 3
  done
  out=$(python3 - "$jsonf" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
for o in d.get("ProductDownloadOptions") or []:
    u = o.get("Uri") or ""
    if u:
        print(u)
PY
)
  rm -f "$jar" "$jsonf"
  printf '%s\n' "$out"
}

# ----------------------------------------------------------------------------- resolve payload
resolve_payload() {
  PAYLOAD_URL=""; PAYLOAD_NAME=""; PAYLOAD_SIZE=""; PAYLOAD_SHA1=""
  PAYLOAD_KIND=""; PAYLOAD_LABEL=""
  case "$MCT_VER" in
    official*) resolve_official ;;
    *)         resolve_catalog ;;
  esac
  [ -n "$PAYLOAD_URL" ] || die "could not resolve a download link"
}

# map a windows language code (en-us, zh-cn, ...) to the name used by the iso api
api_lang_name() {
  case "$1" in
    en-us)     echo "English" ;;
    en-gb)     echo "English (United Kingdom)" ;;
    es-es)     echo "Spanish" ;;
    es-mx)     echo "Spanish (Mexico)" ;;
    pt-br)     echo "Brazilian Portuguese" ;;
    pt-pt)     echo "Portuguese" ;;
    zh-cn)     echo "Chinese (Simplified)" ;;
    zh-tw)     echo "Chinese (Traditional)" ;;
    fr-ca)     echo "French Canadian" ;;
    fr-fr)     echo "French" ;;
    de-de)     echo "German" ;;
    it-it)     echo "Italian" ;;
    ja-jp)     echo "Japanese" ;;
    ko-kr)     echo "Korean" ;;
    ru-ru)     echo "Russian" ;;
    nl-nl)     echo "Dutch" ;;
    pl-pl)     echo "Polish" ;;
    sv-se)     echo "Swedish" ;;
    tr-tr)     echo "Turkish" ;;
    ar-sa)     echo "Arabic" ;;
    he-il)     echo "Hebrew" ;;
    th-th)     echo "Thai" ;;
    hu-hu)     echo "Hungarian" ;;
    cs-cz)     echo "Czech" ;;
    da-dk)     echo "Danish" ;;
    fi-fi)     echo "Finnish" ;;
    el-gr)     echo "Greek" ;;
    nb-no)     echo "Norwegian" ;;
    ro-ro)     echo "Romanian" ;;
    sk-sk)     echo "Slovak" ;;
    sl-si)     echo "Slovenian" ;;
    hr-hr)     echo "Croatian" ;;
    et-ee)     echo "Estonian" ;;
    lv-lv)     echo "Latvian" ;;
    lt-lt)     echo "Lithuanian" ;;
    sr-latn-rs) echo "Serbian Latin" ;;
    uk-ua)     echo "Ukrainian" ;;
    bg-bg)     echo "Bulgarian" ;;
    *)         echo "" ;;
  esac
}

resolve_official() {
  local entry key label eid page fallback want row lang_localized sku urls
  entry=$(printf '%s\n' "${OFFICIAL_TABLE[@]}" | grep "^$MCT_VER|" | head -1)
  [ -n "$entry" ] || die "unknown version: $MCT_VER"
  IFS='|' read -r key label eid page fallback <<< "$entry"
  info "official api: $label"
  info "resolving languages for product edition id $eid"

  api_probe "$page" "$eid"

  want=$(api_lang_name "$LANGCODE")
  [ -n "$want" ] || want=$LANGCODE
  row=$(printf '%s\n' "$API_LANGS" | awk -F'|' -v w="$want" \
    'tolower($1)==tolower(w){print; exit}')
  if [ -z "$row" ] && [ "$LANGCODE" != "en-us" ]; then
    want=$(api_lang_name en-us)
    row=$(printf '%s\n' "$API_LANGS" | awk -F'|' -v w="$want" \
      'tolower($1)==tolower(w){print; exit}')
    [ -n "$row" ] && { warn "language $LANGCODE not offered by the iso api, using en-us"; LANGCODE=en-us; }
  fi
  if [ -z "$row" ]; then
    row=$(printf '%s\n' "$API_LANGS" | head -1)
    LANGCODE=$(printf '%s' "$row" | cut -d'|' -f1 | tr 'A-Z' 'a-z')
    warn "no language match, using $LANGCODE"
  fi
  lang_localized=$(printf '%s' "$row" | cut -d'|' -f2)
  sku=$(printf '%s' "$row" | cut -d'|' -f3)
  [ -n "$sku" ] || die "no sku id for $LANGCODE"
  info "language: ${lang_localized:-$LANGCODE}"

  urls=$(api_links "$page" "$API_SESSION" "$sku") || urls=""
  if [ -z "$urls" ]; then
    if [ -n "$fallback" ]; then
      warn "official iso api unavailable - falling back to the $fallback catalog"
      MCT_VER=$fallback
      resolve_catalog
      return $?
    fi
    return 1
  fi

  # prefer the x64 link
  PAYLOAD_URL=$(printf '%s\n' "$urls" | grep -i 'x64' | head -1)
  [ -n "$PAYLOAD_URL" ] || PAYLOAD_URL=$(printf '%s\n' "$urls" | head -1)
  PAYLOAD_NAME=$(basename "${PAYLOAD_URL%%\?*}")
  case "$PAYLOAD_NAME" in *.iso|*.ISO) ;; *) PAYLOAD_NAME="Windows.iso" ;; esac
  PAYLOAD_KIND=iso
  PAYLOAD_LABEL=$label
  PAYLOAD_SIZE=$(http_size "$PAYLOAD_URL" || true)
}

resolve_catalog() {
  local entry key label build url xml line
  entry=$(printf '%s\n' "${CATALOG_TABLE[@]}" | grep "^$MCT_VER|" | head -1)
  [ -n "$entry" ] || die "unknown version: $MCT_VER"
  IFS='|' read -r key label build url <<< "$entry"
  xml=$(catalog_file "$key") || exit 1
  info "resolving edition / language / arch in products.xml"
  line=$(catalog_resolve "$xml" "$EDITION" "$LANGCODE" "$ARCH") || exit 1
  IFS='|' read -r PAYLOAD_URL PAYLOAD_SIZE PAYLOAD_SHA1 PAYLOAD_NAME EDITION LANGCODE ARCH <<< "$line"
  PAYLOAD_KIND=esd
  PAYLOAD_LABEL="$label"
  [ -n "$PAYLOAD_URL" ] || die "empty FilePath in products.xml"
}

# ----------------------------------------------------------------------------- download
download_payload() {
  local dest="$PWD/$PAYLOAD_NAME" have avail
  if [ -f "$dest" ]; then
    have=$(file_size "$dest")
    if [ -n "$PAYLOAD_SIZE" ] && [ "$have" = "$PAYLOAD_SIZE" ]; then
      info "already downloaded: $dest"
      PAYLOAD_FILE=$dest
      return 0
    fi
    warn "existing file does not match the expected size, resuming it"
  fi
  if [ -n "$PAYLOAD_SIZE" ]; then
    avail=$(df -Pk "$PWD" | awk 'NR==2{print $4*1024}')
    if [ -n "$avail" ] && [ "$avail" -lt "$PAYLOAD_SIZE" ]; then
      die "not enough free space: need $(human "$PAYLOAD_SIZE"), have $(human "$avail")"
    fi
  fi
  info "downloading: $PAYLOAD_URL"
  [ -n "$PAYLOAD_SIZE" ] && info "size: $(human "$PAYLOAD_SIZE")"
  tool_get "$PAYLOAD_URL" "$dest" || die "download failed: $PAYLOAD_URL"
  PAYLOAD_FILE=$dest
  if [ -n "$PAYLOAD_SIZE" ]; then
    have=$(file_size "$dest")
    [ "$have" = "$PAYLOAD_SIZE" ] || warn "size mismatch: got $have, expected $PAYLOAD_SIZE"
  fi
}

verify_payload() {
  [ -f "${PAYLOAD_FILE:-}" ] || return 0
  [ -n "${PAYLOAD_SHA1:-}" ] || { info "no published sha1 for this file, skipping verification"; return 0; }
  info "verifying sha1"
  local got
  got=$(sha1_of "$PAYLOAD_FILE")
  if [ "$got" = "$PAYLOAD_SHA1" ]; then
    ok "sha1 verified: $got"
  else
    fail "sha1 mismatch: got $got expected $PAYLOAD_SHA1"
    return 1
  fi
}

# ----------------------------------------------------------------------------- media extras
write_extras() {
  local dir=$1 k keyid
  mkdir -p "$dir" || return 1
  info "adding media extras to $dir"
  generate_auto_cmd "$dir/auto.cmd"
  if [ -n "$EDITION" ]; then
    k=$(printf '%s\n' "$KEY_TABLE" | grep -F ".$EDITION" | head -1)
    if [ -n "$k" ]; then
      keyid=$(printf '%s' "$k" | sed 's/\..*//')
      printf '[PID]\nValue=%s\n;Edition=%s\n' "$keyid" "$EDITION" > "$dir/PID.txt"
      info "  PID.txt            preselects $EDITION"
    fi
  fi
  case "$MCT_VER" in
    11_*|official11)
      if [ -z "$KEY" ]; then
        printf '[Channel]\n_Default\n' > "$dir/EI.cfg"
        info "  EI.cfg             no product key prompt (windows 11)"
      fi ;;
  esac
  generate_autounattend_xml "$dir/AutoUnattend.xml"
  info "  AutoUnattend.xml   local account on windows 11 home (place in boot.wim)"
  if [ -d "$PWD/\$ISO\$" ]; then
    cp -a "$PWD/\$ISO\$/." "$dir/" && info "  \$ISO\$             directory content copied"
  fi
  if [ -d "$PWD/bypass11" ]; then
    cp -a "$PWD/bypass11" "$dir/" && info "  bypass11           skip tpm / secure boot toggles"
  fi
}

inject_iso() {
  local iso=$1 dir=$2 tmp="${1}.mct.tmp" rc=0 f
  need xorriso || { warn "xorriso not found, extras stay next to the iso"; return 0; }
  [ -f "$dir/auto.cmd" ] || return 0
  local args=(-indev "$iso" -outdev "$tmp" -boot_image any replay)
  [ -f "$dir/auto.cmd" ]         && args+=(-map "$dir/auto.cmd" /auto.cmd)
  [ -f "$dir/AutoUnattend.xml" ] && args+=(-map "$dir/AutoUnattend.xml" /autounattend.xml)
  [ -f "$dir/PID.txt" ]          && args+=(-map "$dir/PID.txt" /sources/PID.txt)
  [ -f "$dir/EI.cfg" ]           && args+=(-map "$dir/EI.cfg" /sources/EI.cfg)
  if [ -d "$dir/\$ISO\$" ]; then
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      args+=(-map "$f" "/${f#"$dir/\$ISO\$/"}")
    done < <(find "$dir/\$ISO\$" -type f 2>/dev/null)
  fi
  info "injecting extras into ${iso##*/}"
  xorriso "${args[@]}" -commit -end >/dev/null 2>"$dir/.xorriso.log" || rc=$?
  if [ "$rc" -eq 0 ] && [ -f "$tmp" ]; then
    mv -f "$tmp" "$iso"
    ok "iso updated, boot record preserved"
    rm -f "$dir/.xorriso.log"
    return 0
  fi
  warn "could not modify the iso, the original is kept and extras are in $dir"
  [ -f "$dir/.xorriso.log" ] && tail -5 "$dir/.xorriso.log" >&2
  rm -f "$tmp"
  return 1
}

generate_auto_cmd() {
  # exactly the auto.cmd MediaCreationTool.bat writes to the media
  local out=$1 skip=1
  [ -n "$DEF" ] && skip=0
  local switch="${EDITION_SWITCH:-}"
  local auto_options="/Auto Upgrade /MigChoice Upgrade $OPTIONS_OPTS /SkipSummary /Eula Accept"
  [ -n "$NO_UPDATE" ] && auto_options="$auto_options /DynamicUpdate Disable"
  mkdir -p "$(dirname "$out")"
  {
    printf '@echo off& title Auto Upgrade  ||  supports Ultimate / PosReady / Embedded / LTSC / Enterprise Eval\r\n'
    printf 'set "EDITION_SWITCH=%s"\r\n' "$switch"
    printf 'set "SKIP_11_SETUP_CHECKS=%s"\r\n' "$skip"
    printf 'set OPTIONS=%s\r\n\r\n' "$auto_options"
    sed -e 's/\r$//' -e 's/$/\r/'
  } > "$out" <<'__MCT_AUTO_CMD_BODY__'
pushd "%~dp0" & for %%w in (%1) do pushd %%w
for %%i in ("x86\" "x64\" "") do if exist "%%~isources\setupprep.exe" set "dir=%%~i"
pushd "%dir%sources" || (echo "%dir%sources" not found! script should be run from windows setup media & timeout /t 5 & exit /b)

::# start sources\setup if under winpe (when booted from media) [Shift] + [F10]: c:\auto or d:\auto or e:\auto etc.
reg query "HKLM\Software\Microsoft\Windows NT\CurrentVersion\WinPE">nul 2>nul && (
 for %%s in (sCPU sRAM sSecureBoot sStorage sTPM) do reg add HKLM\SYSTEM\Setup\LabConfig /f /v Bypas%%sCheck /d 1 /t reg_dword
 start "WinPE" sources\setup.exe & exit /b 
) 

::# init variables
setlocal EnableDelayedExpansion
set "PATH=%SystemRoot%\System32;%SystemRoot%\System32\windowspowershell\v1.0\;%PATH%"
set "PATH=%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\windowspowershell\v1.0\;%PATH%"

::# elevate so that workarounds can be set under windows
fltmc >nul || (set _="%~f0" %*& powershell -nop -c start -verb runas cmd \"/d /x /c call $env:_\"& exit /b)

::# undo any previous regedit edition rename (if upgrade was interrupted)
set "NT=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
for %%v in (CompositionEditionID EditionID ProductName) do (
 call :reg_query "%NT%" %%v_undo %%v
 if defined %%v reg delete "%NT%" /v %%v_undo /f & for %%A in (32 64) do reg add "%NT%" /v %%v /d "!%%v!" /f /reg:%%A 
) >nul 2>nul

::# get current version
for %%v in (CompositionEditionID EditionID ProductName CurrentBuildNumber) do call :reg_query "%NT%" %%v %%v
for /f "tokens=2-3 delims=[." %%i in ('ver') do for %%s in (%%i) do set /a Version=%%s*10+%%j

::# WIM_INFO w_5=wim_5th b_5=build_5th p_5=patch_5th a_5=arch_5th l_5=lang_5th e_5=edi_5th d_5=desc_5th i_5=edi_5th i_Core=index
set "0=%~f0"& set wim=& set ext=.esd& if exist install.wim (set ext=.wim) else if exist install.swm set ext=.swm
set snippet=powershell -nop -c iex ([io.file]::ReadAllText($env:0)-split'#[:]wim_info[:]')[1]; WIM_INFO install%ext% 0 0  
set w_count=0& for /f "tokens=1-7 delims=," %%i in ('"%snippet%"') do (set w_%%i=%%i,%%j,%%k,%%l,%%m,%%n,%%o& set /a w_count+=1
set b_%%i=%%j& set p_%%i=%%k& set a_%%i=%%l& set l_%%i=%%m& set e_%%i=%%n& set d_%%i=%%o& set i_%%n=%%i& set i_%%i=%%n)

::# print available editions in install.esd via wim_info snippet
echo;------------------------------------------------------------------------------------
for /l %%i in (1,1,%w_count%) do call echo;%%w_%%i%%
echo;------------------------------------------------------------------------------------

::# get requested edition in EI.cfg or PID.txt or OPTIONS
if exist product.ini for /f "tokens=1,2 delims==" %%O in (product.ini) do if not "%%P" equ "" (set pid_%%O=%%P& set pn_%%P=%%O)
set EI=& set Name=& set eID=& set reg=& set "cfg_filter=EditionID Channel OEM Retail Volume _Default VL 0 1 ^$"
if exist EI.cfg for /f "tokens=*" %%i in ('findstr /v /i /r "%cfg_filter%" EI.cfg') do (set EI=%%i& set eID=%%i)
if exist PID.txt for /f "delims=;" %%i in (PID.txt) do set %%i 2>nul
if not defined Value for %%s in (%OPTIONS%) do if defined pn_%%s (set Name=!pn_%%s!& set Name=!Name:gvlk=!)
if defined Value if not defined Name for %%s in (%Value%) do (set Name=!pn_%%s!& set Name=!Name:gvlk=!)
if defined EDITION_SWITCH (set eID=%EDITION_SWITCH%) else if defined Name for %%s in (%Name%) do (set eID=%Name%)
if not defined eID set eID=%EditionID%& if not defined EditionID set eID=Professional& set EditionID=Professional
if /i "%EditionID%" equ "%eID%" (set changed=) else set changed=1

::# upgrade matrix - now also for Enterprise Eval - automatically pick edition that would keep files and apps
if /i CoreCountrySpecific equ %eID% set "comp=!eID!" & set "reg=!eID!" & if not defined i_!eID! set "eID=Core"
if /i CoreSingleLanguage  equ %eID% set "comp=Core"  & set "reg=!eID!" & if not defined i_!eID! set "eID=Core"
for %%e in (Starter HomeBasic HomePremium CoreConnectedCountrySpecific CoreConnectedSingleLanguage CoreConnected Core) do (
 if /i %%e  equ %eID% set "comp=Core"  & set "eID=Core"
 if /i %%eN equ %eID% set "comp=CoreN" & set "eID=CoreN"
 if /i %%e  equ %eID% if not defined i_Core  set "eID=Professional"  & if not defined reg set "reg=Core"
 if /i %%eN equ %eID% if not defined i_CoreN set "eID=ProfessionalN" & if not defined reg set "reg=CoreN"
)
for %%e in (Ultimate ProfessionalStudent ProfessionalCountrySpecific ProfessionalSingleLanguage) do (
  if /i %%e equ %eID% (set "eID=Professional") else if /i %%eN equ %eID% set "eID=ProfessionalN"
)
for %%e in (EnterpriseG EnterpriseS IoTEnterpriseS IoTEnterprise Embedded) do (
  if /i %%e equ %eID% (set "eID=Enterprise") else if /i %%eN equ %eID% set "eID=EnterpriseN"
)
for %%e in (Enterprise EnterpriseS) do (
  if /i %%eEval equ %eID% (set "eID=Enterprise") else if /i %%eNEval equ %eID% set "eID=EnterpriseN"
)
if /i Enterprise  equ %eID% set "comp=!eID!" & if not defined i_!eID! set "eID=Professional"  & set "reg=!comp!"
if /i EnterpriseN equ %eID% set "comp=!eID!" & if not defined i_!eID! set "eID=ProfessionalN" & set "reg=!comp!"
for %%e in (Education ProfessionalEducation ProfessionalWorkstation Professional Cloud) do (
  if /i %%eN equ %eID% set "comp=EnterpriseN"  & if not defined reg set "reg=%%eN"
  if /i %%e  equ %eID% set "comp=Enterprise"   & if not defined reg set "reg=%%e"
  if /i %%eN equ %eID% set "eID=ProfessionalN" & if defined i_%%eN  set "eID=%%eN"
  if /i %%e  equ %eID% set "eID=Professional"  & if defined i_%%e   set "eID=%%e"
)
set index=& set lst=Professional& for /l %%i in (1,1,%w_count%) do if /i !i_%%i! equ !eID! set "index=%%i" & set "eID=!i_%%i!" 
if not defined index set index=1& set eID=!i_1!& if defined i_%lst% set "index=!i_%lst%!" & set "eID=%lst%"& set "comp=Enterprise"
set Build=!b_%index%!& set OPTIONS=%OPTIONS% /ImageIndex %index%& if defined changed if not defined reg set "reg=!eID!"
echo;Current edition: %EditionID% & echo;Regedit edition: %reg% & echo;Index: %index%  Image: %eID%
timeout /t 10

::# disable upgrade blocks
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f /v DisableWUfBSafeguards /d 1 /t reg_dword >nul 2>nul  

::# prevent usage of MCT for intermediary upgrade in Dynamic Update (causing 7 to 19H1 instead of 7 to 21H2 for example) 
if "%Build%" gtr "15063" (set OPTIONS=%OPTIONS% /UpdateMedia Decline)

::# skip windows 11 upgrade checks: add launch option trick if old-style 0-byte file trick is not on the media  
if "%Build%" lss "22000" set /a SKIP_11_SETUP_CHECKS=0
reg add HKLM\SYSTEM\Setup\MoSetup /f /v AllowUpgradesWithUnsupportedTPMorCPU /d 1 /t reg_dword >nul 2>nul &rem ::# TPM 1.2+ only
if "%SKIP_11_SETUP_CHECKS%" equ "1" cd.>appraiserres.dll 2>nul & rem ::# writable media only
for %%A in (appraiserres.dll) do if %%~zA gtr 0 (set TRICK=/Product Server ) else (set TRICK=)
if "%SKIP_11_SETUP_CHECKS%" equ "1" (set OPTIONS=%TRICK%%OPTIONS%)

::# auto upgrade with edition lie workaround to keep files and apps - all 1904x builds allow up/downgrade between them
if defined reg call :rename %reg%
start "auto" setupprep.exe %OPTIONS%
echo;DONE

EXIT /b

:rename EditionID
set "NT=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
for %%v in (CompositionEditionID EditionID ProductName) do reg add "%NT%" /v %%v_undo /d "!%%v!" /f >nul 2>nul
for %%A in (32 64) do ( 
 reg add "%NT%" /v CompositionEditionID /d "%comp%" /f /reg:%%A
 reg add "%NT%" /v EditionID /d "%~1" /f /reg:%%A
 reg add "%NT%" /v ProductName /d "%~1" /f /reg:%%A
) >nul 2>nul
exit /b

:reg_query [USAGE] call :reg_query "HKCU\Volatile Environment" Value variable
(for /f "tokens=2*" %%R in ('reg query "%~1" /v "%~2" /se "|" %4 2^>nul') do set "%~3=%%S") & exit /b

#:WIM_INFO:# [PARAMS]: "file" [optional]Index or 0 = all  Output 0 = txt 1 = xml 2 = file.txt 3 = file.xml 4 = xml object
set ^ #=;$f0=[io.file]::ReadAllText($env:0); $0=($f0-split '#[:]WIM_INFO[:]' ,3)[1]; $1=$env:1-replace'([`@$])','`$1'; iex($0+$1)
set ^ #=& set "0=%~f0"& set 1=;WIM_INFO %*& powershell -nop -c "%#%"& exit /b %errorcode%
function WIM_INFO ($file = 'install.esd', $index = 0, $out = 0) { :info while ($true) {
  $block = 2097152; $bytes = new-object 'Byte[]' ($block); $begin = [uint64]0; $final = [uint64]0; $limit = [uint64]0
  $steps = [int]([uint64]([IO.FileInfo]$file).Length / $block - 1); $enc = [Text.Encoding]::GetEncoding(28591); $delim = @()
  foreach ($d in '/INSTALLATIONTYPE','/WIM') {$delim += $enc.GetString([Text.Encoding]::Unicode.GetBytes([char]60+ $d +[char]62))}
  $f = new-object IO.FileStream ($file, 3, 1, 1); $p = 0; $p = $f.Seek(0, 2)
  for ($o = 1; $o -le $steps; $o++) { 
    $p = $f.Seek(-$block, 1); $r = $f.Read($bytes, 0, $block); if ($r -ne $block) {write-host invalid block $r; break}
    $u = [Text.Encoding]::GetEncoding(28591).GetString($bytes); $t = $u.LastIndexOf($delim[0], [StringComparison]::Ordinal) 
    if ($t -lt 0) { $p = $f.Seek(-$block, 1)} else { [void]$f.Seek(($t -$block), 1)
      for ($o = 1; $o -le $block; $o++) { [void]$f.Seek(-2, 1); if ($f.ReadByte() -eq 0xfe) {$begin = $f.Position; break} }
      $limit = $f.Length - $begin; if ($limit -lt $block) {$x = $limit} else {$x = $block}
      $bytes = new-object 'Byte[]' ($x); $r = $f.Read($bytes, 0, $x) 
      $u = [Text.Encoding]::GetEncoding(28591).GetString($bytes); $t = $u.IndexOf($delim[1], [StringComparison]::Ordinal)
      if ($t -ge 0) {[void]$f.Seek(($t + 12 -$x), 1); $final = $f.Position} ; break } }
  if ($begin -gt 0 -and $final -gt $begin) {
    $x = $final - $begin; [void]$f.Seek(-$x, 1); $bytes = new-object 'Byte[]' ($x); $r = $f.Read($bytes, 0, $x)
    if ($r -ne $x) {$f.Dispose(); break} else {[xml]$xml = [Text.Encoding]::Unicode.GetString($bytes); $f.Dispose()}
  } else {$f.Dispose()} ; break :info }
  if ($out -eq 1) {[console]::OutputEncoding=[Text.Encoding]::UTF8; $xml.Save([Console]::Out); ''; return} 
  if ($out -eq 3) {try{$xml.Save(($file-replace'esd$','xml'))}catch{}; return}; if ($out -eq 4) {return $xml}
  $txt = ''; foreach ($i in $xml.WIM.IMAGE) {if ($index -gt 0 -and $($i.INDEX) -ne $index) {continue}; [int]$a='1'+$i.WINDOWS.ARCH
  $txt+= $i.INDEX+','+$i.WINDOWS.VERSION.BUILD+','+$i.WINDOWS.VERSION.SPBUILD+','+$(@{10='x86';15='arm';19='x64';112='arm64'}[$a])
  $txt+= ','+$i.WINDOWS.LANGUAGES.LANGUAGE+','+$i.WINDOWS.EDITIONID+','+$i.NAME+[char]13+[char]10}; $txt=$txt-replace',(?=,)',', '
  if ($out -eq 2) {try{[io.file]::WriteAllText(($file-replace'esd$','txt'),$txt)}catch{}; return}; if ($out -eq 0) {return $txt}
} #:WIM_INFO:# Quick WIM SWM ESD ISO info v2 - lean and mean snippet by AveYo, 2021
__MCT_AUTO_CMD_BODY__
  info "  auto.cmd            upgrade keeping files and apps, skip tpm checks"
}

generate_autounattend_xml() {
  local out=$1
  mkdir -p "$(dirname "$out")"
  cat > "$out" <<'__MCT_UNATTEND__'
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="windowsPE"><component name="Microsoft-Windows-Setup" processorArchitecture="amd64" language="neutral"
   xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   publicKeyToken="31bf3856ad364e35" versionScope="nonSxS">
    <UserData><ProductKey><Key>AAAAA-VVVVV-EEEEE-YYYYY-OOOOO</Key><WillShowUI>OnError</WillShowUI></ProductKey></UserData>
    <ComplianceCheck><DisplayReport>Never</DisplayReport></ComplianceCheck><Diagnostics><OptIn>false</OptIn></Diagnostics>
    <DynamicUpdate><Enable>true</Enable><WillShowUI>Never</WillShowUI></DynamicUpdate><EnableNetwork>true</EnableNetwork>
  </component></settings>
  <settings pass="specialize"><component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" language="neutral"
   xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   publicKeyToken="31bf3856ad364e35" versionScope="nonSxS">
    <RunSynchronous>
      <!-- offline local account via OOBE\BYPASSNRO on every site but literally no one credits AveYo for sharing it -->
      <RunSynchronousCommand wcm:action="add"><Order>1</Order>
        <Path>reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t reg_dword /d 1 /f</Path>
      </RunSynchronousCommand>
      <!-- hide unsupported nag on update settings - 25H1 is not a typo ;) -->
      <RunSynchronousCommand wcm:action="add"><Order>2</Order>
        <Path>reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v TargetReleaseVersion /d 1 /t reg_dword /f</Path>
      </RunSynchronousCommand>
      <RunSynchronousCommand wcm:action="add"><Order>3</Order>
        <Path>reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v TargetReleaseVersionInfo /d 25H1 /f</Path>
      </RunSynchronousCommand>
    </RunSynchronous>
  </component></settings>
  <settings pass="oobeSystem"><component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" language="neutral"
   xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   publicKeyToken="31bf3856ad364e35" versionScope="nonSxS">
    <OOBE>
      <HideLocalAccountScreen>false</HideLocalAccountScreen><HideOnlineAccountScreens>false</HideOnlineAccountScreens>
      <HideWirelessSetupInOOBE>false</HideWirelessSetupInOOBE><ProtectYourPC>3</ProtectYourPC>
    </OOBE>
    <FirstLogonCommands>
      <!-- hide unsupported nag on desktop - originally shared by awuctl @ MDL -->
      <SynchronousCommand wcm:action="add"><Order>1</Order>
        <CommandLine>reg add "HKCU\Control Panel\UnsupportedHardwareNotificationCache" /v SV1 /d 0 /t reg_dword /f</CommandLine>
      </SynchronousCommand><SynchronousCommand wcm:action="add"><Order>2</Order>
        <CommandLine>reg add "HKCU\Control Panel\UnsupportedHardwareNotificationCache" /v SV2 /d 0 /t reg_dword /f</CommandLine>
      </SynchronousCommand>
    </FirstLogonCommands>
  </component></settings>
</unattend>
__MCT_UNATTEND__
}

# ----------------------------------------------------------------------------- usb
list_usb() {
  if need lsblk; then
    lsblk -dnpo NAME,SIZE,RM,TRAN,MODEL --pairs 2>/dev/null |
      grep -E 'RM="1"|TRAN="usb"' |
      sed -e 's/NAME="\([^"]*\)"/\1/' -e 's/ RM="/  rm="/' -e 's/ TRAN="/  tran="/' \
          -e 's/ MODEL="/  model="/' -e 's/"//g'
  fi
}

write_usb() {
  local iso=${PAYLOAD_FILE:-} cands size have t dev
  [ -f "$iso" ] || die "nothing to write, no image downloaded"
  cands=$(list_usb)
  if [ -z "$cands" ]; then
    warn "no removable usb device detected by lsblk, all block devices:"
    say "$(lsblk -dno NAME,SIZE,MODEL 2>/dev/null | head -20)" >&2
  else
    say "removable devices:" >&2
    say "$cands" >&2
  fi
  [ -n "$USB_TARGET" ] || USB_TARGET=$(ask "type the target device name (example sdb, no /dev/ prefix)")
  [ -n "$USB_TARGET" ] || die "no target selected"
  USB_TARGET=${USB_TARGET#/dev/}
  dev="/dev/$USB_TARGET"
  [ -b "$dev" ] || die "$dev is not a block device"
  size=$(lsblk -bdno SIZE "$dev" 2>/dev/null || echo 0)
  have=$(file_size "$iso")
  if [ "$size" -gt 0 ] && [ "$size" -lt "$have" ]; then
    t=$(ask "$dev ($(human "$size")) is smaller than the image ($(human "$have")), continue? [y/N]")
    case "$t" in y*|Y*) ;; *) die "aborted" ;; esac
  fi
  t=$(ask "ALL DATA ON $dev WILL BE DESTROYED, type the device name to confirm")
  [ "$t" = "$USB_TARGET" ] || die "aborted"
  info "writing ${iso##*/} to $dev"
  if dd if="$iso" of="$dev" bs=4M status=progress conv=fsync; then
    sync
    ok "usb media created on $dev"
  else
    die "dd failed on $dev"
  fi
}

# ----------------------------------------------------------------------------- menus
banner() {
  cat >&2 <<BANNER
${C_BOLD}${C_BLUE}MediaCreationTool${C_RESET}${C_WHITE} ${MCT_SH_VERSION}${C_RESET}  ${C_GRAY}linux port${C_RESET}
${C_GRAY}Microsoft-hosted source links only, no third party tools${C_RESET}
BANNER
  printf '%s Detected Media ' "$C_MAGENTA" >&2
  printf '%s %-8s %s' "$C_CYAN"  "${MCT_VER:-?}" "$C_RESET" >&2
  printf '%s %-7s %s' "$C_GREEN" "${LANGCODE:-?}" "$C_RESET" >&2
  printf '%s %-24s %s' "$C_YELLOW" "${EDITION:-?}" "$C_RESET" >&2
  printf '%s %-4s %s\n' "$C_WHITE" "${ARCH:-?}" "$C_RESET" >&2
  say "" >&2
}

menu_presets() {
  banner
  cat >&2 <<MENU
${C_GRAY}1  Auto Upgrade  : build the windows upgrade kit (auto.cmd, PID.txt, EI.cfg)${C_RESET}
${C_GRAY}2    Auto ISO    : download the iso / esd in the current folder${C_RESET}
${C_GRAY}3    Auto USB    : download the image and write it to a usb stick${C_RESET}
${C_GRAY}4     Select     : pick version, edition, language, arch and target${C_RESET}
${C_GRAY}5  MCT Defaults  : plain download, no extra files added${C_RESET}
${C_BOLD}6      Exit      : quit the script${C_RESET}

${C_GRAY}1-5 adds to media: PID.txt, EI.cfg, \$ISO\$ dir, auto.cmd for upgrade and tpm checks${C_RESET}
${C_GRAY}run with ${C_WHITE}def${C_GRAY} to always get untouched media${C_RESET}

MENU
}

menu_versions() {
  local i=1 entry key label rest
  say "" >&2
  say "${C_BOLD} official iso (microsoft software-download api)${C_RESET}" >&2
  for entry in "${OFFICIAL_TABLE[@]}"; do
    IFS='|' read -r key label rest <<< "$entry"
    printf '%s %2d  %s %s\n' "$C_BLUE" "$i" "$label" "$C_RESET" >&2
    i=$((i+1))
  done
  say "${C_BOLD} catalog esd (products.cab, 1507 - 11 23H2)${C_RESET}" >&2
  for entry in "${CATALOG_TABLE[@]}"; do
    IFS='|' read -r key label rest <<< "$entry"
    printf '%s %2d  %s %s\n' "$C_BLUE" "$i" "$label" "$C_RESET" >&2
    i=$((i+1))
  done
  say "" >&2
}

pick_preset() {
  [ -n "$PRESET" ] && return 0
  menu_presets
  local n
  while :; do
    n=$(ask "preset (1-6)")
    case "$n" in
      1) PRESET=auto ;;
      2) PRESET=iso ;;
      3) PRESET=usb ;;
      4) PRESET=select ;;
      5) PRESET=def ;;
      6|q|Q) say "${C_GREEN}bye${C_RESET}"; exit 0 ;;
      "") die "no selection" ;;
      *) warn "choose 1 to 6" ;;
    esac
    [ -n "$PRESET" ] && break
  done
  say "" >&2
}

pick_version() {
  [ -n "$MCT_VER" ] && return 0
  menu_versions
  local total n entry
  total=$(( ${#OFFICIAL_TABLE[@]} + ${#CATALOG_TABLE[@]} ))
  while :; do
    n=$(ask "version (1-$total, q quits)")
    case "$n" in
      q|Q) say "${C_GREEN}bye${C_RESET}"; exit 0 ;;
      "")  die "no selection" ;;
    esac
    if [ "$n" -ge 1 ] 2>/dev/null && [ "$n" -le "$total" ] 2>/dev/null; then
      if [ "$n" -le "${#OFFICIAL_TABLE[@]}" ]; then
        entry=$(printf '%s\n' "${OFFICIAL_TABLE[@]}" | sed -n "${n}p")
      else
        entry=$(printf '%s\n' "${CATALOG_TABLE[@]}" | sed -n "$(( n - ${#OFFICIAL_TABLE[@]} ))p")
      fi
      MCT_VER=$(printf '%s' "$entry" | cut -d'|' -f1)
      break
    fi
    warn "choose 1 to $total"
  done
  say "" >&2
}

pick_edition() {
  [ -n "$EDITION" ] && return 0
  case "$MCT_VER" in official*) EDITION="Professional"; return 0 ;; esac
  say "editions: $EDITION_LIST" >&2
  EDITION=$(ask "edition")
  EDITION=${EDITION:-Professional}
}

pick_lang() {
  [ -n "$LANGCODE" ] && return 0
  LANGCODE=$(ask "language code (example en-us)")
  LANGCODE=${LANGCODE:-$(detect_lang)}
}

pick_arch() {
  [ -n "$ARCH" ] && return 0
  case "$MCT_VER" in
    11_*|official11) ARCH=x64; info "windows 11 is x64 only"; return 0 ;;
  esac
  ARCH=$(ask "arch (x64/x86)")
  ARCH=${ARCH:-$(detect_arch)}
}

# ----------------------------------------------------------------------------- flows
do_upgrade_kit() {
  banner
  local kit="$PWD/media-extras"
  if [ "$DRY_RUN" -eq 1 ]; then
    info "dry run: would generate $kit/{auto.cmd,PID.txt,EI.cfg,AutoUnattend.xml} + bypass11"
    return 0
  fi
  write_extras "$kit"
  say "" >&2
  ok "upgrade kit created in $kit"
  cat >&2 <<NOTES

${C_GRAY}copy the kit next to the windows setup media (the folder that has sources\setupprep.exe),
then run auto.cmd from an elevated prompt to upgrade keeping files and apps.
put AutoUnattend.xml inside boot.wim to enable a local account on windows 11 home.
NOTES
}

do_download() {
  banner
  resolve_payload
  say "" >&2
  info "source:  $PAYLOAD_KIND"
  info "label:   $PAYLOAD_LABEL"
  info "file:    $PAYLOAD_NAME"
  [ -n "$PAYLOAD_SIZE" ] && info "size:    $(human "$PAYLOAD_SIZE")"
  [ -n "$PAYLOAD_SHA1" ] && info "sha1:    $PAYLOAD_SHA1"
  info "url:     $PAYLOAD_URL"
  say "" >&2
  if [ "$DRY_RUN" -eq 1 ]; then
    if http_ok "$PAYLOAD_URL"; then ok "link is alive ($(human "$PAYLOAD_SIZE"))"
    else fail "link is not reachable"; return 1; fi
    return 0
  fi
  download_payload
  verify_payload || exit 1

  local extras_dir="$PWD/media-extras"
  if [ "$PRESET" != def ] && [ -z "$DEF" ]; then
    write_extras "$extras_dir" || true
    if [ "$PAYLOAD_KIND" = iso ] && [ -f "$PAYLOAD_FILE" ]; then
      inject_iso "$PAYLOAD_FILE" "$extras_dir" || true
    else
      info "esd payload: keep the extras with the media, run auto.cmd from inside windows"
    fi
  fi

  [ "$PRESET" = usb ] && write_usb
  say "" >&2
  ok "$PAYLOAD_FILE"
}

# ----------------------------------------------------------------------------- arguments
is_version_arg() {
  case "$1" in
    1507|th1|1511|th2|1607|1610|rs1|1703|1704|rs2|1709|1710|rs3|1803|1804|rs4|\
    1809|1810|rs5|1903|19H1|1904|19h1|1909|19H2|2000|19h2|20H1|2004|20h1|\
    20H2|2009|20h2|21H1|2104|21h1|21H2|2109|21h2|22H2|2210|22h2|11_21H2|2110|\
    11_22H2|2209|11_23H2|2310|23h2|latest|official11|official10|11|10)
      return 0 ;;
    *) return 1 ;;
  esac
}

version_from_arg() {
  case "$1" in
    1507|th1) echo 1507 ;;
    1511|th2) echo 1511 ;;
    1607|1610|rs1) echo 1607 ;;
    1703|1704|rs2) echo 1703 ;;
    1709|1710|rs3) echo 1709 ;;
    1803|1804|rs4) echo 1803 ;;
    1809|1810|rs5) echo 1809 ;;
    1903|19H1|1904|19h1) echo 1903 ;;
    1909|19H2|2000|19h2) echo 1909 ;;
    20H1|2004|20h1) echo 20H1 ;;
    20H2|2009|20h2) echo 20H2 ;;
    21H1|2104|21h1) echo 21H1 ;;
    21H2|2109|21h2) echo 21H2 ;;
    22H2|2210|22h2) echo 22H2 ;;
    11_21H2|2110) echo 11_21H2 ;;
    11_22H2|2209) echo 11_22H2 ;;
    11_23H2|2310|23h2|latest) echo 11_23H2 ;;
    official11|11) echo official11 ;;
    official10|10) echo official10 ;;
  esac
}

edition_from_arg() {
  local canon
  canon=$(printf '%s' "$1" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
  case "$canon" in
    Home) canon=Core ;; HomeN) canon=CoreN ;;
    Pro) canon=Professional ;; ProN) canon=ProfessionalN ;;
    Edu) canon=Education ;; EduN) canon=EducationN ;;
  esac
  case " $EDITION_LIST " in
    *" $canon "*) printf '%s' "$canon" ;;
  esac
}

parse_args() {
  local a
  while [ $# -gt 0 ]; do
    a=$1
    case "$a" in
      -h|--help) usage ;;
      --dry-run) DRY_RUN=1 ;;
      auto|upgrade) PRESET=auto ;;
      iso)          PRESET=iso ;;
      usb)          PRESET=usb ;;
      select)       PRESET=select ;;
      def)          DEF=1 ;;
      no_update)    NO_UPDATE=1 ;;
      hide)         : ;;
      x64|x86)      ARCH=$a ;;
      *)
        if is_version_arg "$a"; then
          MCT_VER=$(version_from_arg "$a")
        elif printf '%s' "$a" | grep -qiE '^[a-z]{2}-[a-z]{2}$'; then
          LANGCODE=$(printf '%s' "$a" | tr 'A-Z' 'a-z')
        elif printf '%s' "$a" | grep -qiE '^[a-z]{2}_[a-z]{2}(\.utf-8)?$'; then
          LANGCODE=$(printf '%s' "$a" | tr 'A-Z' 'a-z' | sed 's/_/-/; s/\.utf-8//')
        else
          local e
          e=$(edition_from_arg "$a")
          [ -n "$e" ] && EDITION=$e
        fi ;;
    esac
    shift
  done
}

# ----------------------------------------------------------------------------- main
main() {
  parse_args "$@"
  check_deps
  LANGCODE=$(printf '%s' "${LANGCODE:-$(detect_lang)}" | tr 'A-Z' 'a-z')
  [ "$LANGCODE" = "en_us" ] && LANGCODE=en-us
  ARCH=${ARCH:-$(detect_arch)}
  EDITION=${EDITION:-Professional}

  pick_preset
  if [ "$PRESET" = auto ]; then
    pick_version
    pick_edition; pick_lang; pick_arch
    do_upgrade_kit
    exit 0
  fi
  pick_version
  if [ "$PRESET" = select ]; then
    pick_edition; pick_lang; pick_arch
  fi
  case "$MCT_VER" in 11_*|official11) ARCH=x64 ;; esac
  do_download
  exit 0
}

# run only when executed, so the functions can be sourced by tests
if [ "${BASH_SOURCE[0]:-$0}" = "$0" ]; then
  main "$@"
fi
