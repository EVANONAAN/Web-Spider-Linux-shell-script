#!/usr/bin/env bash
# Spider start URLs/domains/IPs and produce a unique URL list.
#
# !!! This script requires the program wget !!!
#
# Extensive help is here:
# https://github.com/Pryodon/Web-Spider-Linux-shell-script/
#
# Usage:
#   webspider [--http|--https]
#             [--video|--audio|--images|--pages|--files|--all]
#             [--ext 'pat|tern'] [--delay SECONDS] [--status-200]
#             [--no-robots]
#             [--sitemap-txt] [--sitemap-xml]
#             <links.txt | URL...>
#
# Modes (choose one; default is --video):
#   --video    : video files only (mp4|mkv|avi|mov|wmv|flv|webm|m4v|ogv|ts|m2ts)
#   --audio    : audio files only (mp3|mpa|mp2|aac|wav|flac|m4a|ogg|opus|wma|alac|aif|aiff)
#   --images   : image files only (jpg|jpeg|png|gif|webp|bmp|tiff|svg|avif|heic|heif)
#   --pages    : directories (.../) + page-like extensions (html|htm|shtml|xhtml|php|phtml|asp|aspx|jsp|jspx|cfm|cgi|pl|do|action|md|markdown)
#   --files    : all files (exclude directories and .html/.htm pages)
#   --all      : everything (dirs + pages + files)
#
# Options:
#   --ext PAT       : override extension pattern used by --video/--audio/--images/--pages
#   --delay S       : polite crawl delay in seconds (default: 0.5). Accepts decimals. Uses wget --wait + --random-wait.
#   --status-200    : only keep URLs that returned HTTP 200 OK (adds -S to wget and parses statuses)
#   --no-robots     : ignore robots.txt (default: respect robots)
#   --sitemap-txt   : write sitemap.txt (plain newline-separated list of final URLs)
#   --sitemap-xml   : write sitemap.xml (Sitemaps.org XML from final URLs)
#   --http|--https  : default scheme for scheme-less inputs (default: https)
#   -h, --help      : show this help
#
# Notes:
#   Single-dash forms work too: -video, -audio, -images, -pages, -files, -all, -ext, -delay, -status-200, -no-robots, -sitemap-txt, -sitemap-xml
#   Use -- to end options if a path starts with a dash.

set -Eeuo pipefail
trap 'echo "[ERROR] $0:$LINENO: $BASH_COMMAND" >&2' ERR

PROG="${0##*/}"

DEFAULT_SCHEME="https"
MODE="video"          # video | audio | images | pages | files | all
EXT_PATTERN=""        # set from MODE unless overridden by --ext
DELAY="0.5"
STATUS_200=0
NO_ROBOTS=0
SITEMAP_TXT=0
SITEMAP_XML=0
LOG_FILE="log"
OUTPUT_URLS="urls"

usage() {
  cat <<EOF
 !!! This script requires the program wget !!!

Usage:
  $PROG [--http|--https]
        [--video|--audio|--images|--pages|--files|--all]
        [--ext 'pat|tern'] [--delay SECONDS] [--status-200]
        [--no-robots]
        [--sitemap-txt] [--sitemap-xml]
        <links.txt | URL...>

Modes (default: --video):
  --video    : video files only (mp4|mkv|avi|mov|wmv|flv|webm|m4v|ogv|ts|m2ts)
  --audio    : audio files only (mp3|mpa|mp2|aac|wav|flac|m4a|ogg|opus|wma|alac|aif|aiff)
  --images   : image files only (jpg|jpeg|png|gif|webp|bmp|tiff|svg|avif|heic|heif)
  --pages    : directories (â€¦/) + page-like extensions (html|htm|shtml|xhtml|php|phtml|asp|aspx|jsp|jspx|cfm|cgi|pl|do|action|md|markdown)
  --files    : all files (exclude directories and .html/.htm pages)
  --all      : everything (dirs + pages + files)

Options:
  --ext PAT       : override extension pattern used by --video/--audio/--images/--pages
  --delay S       : polite crawl delay in seconds (default: 0.5)
  --status-200    : only keep URLs that returned HTTP 200 OK
  --no-robots     : ignore robots.txt (default is to respect robots)
  --sitemap-txt   : write sitemap.txt from the final URL list
  --sitemap-xml   : write sitemap.xml from the final URL list
  --http|--https  : default scheme for scheme-less inputs
  -h, --help      : show this help

Examples:
  $PROG https://www.example.com/
  $PROG --images --delay 1.0 example.com/images/
  $PROG --http --status-200 --sitemap-txt 192.168.1.50:8080 /path/to/url-list.txt
     It can do multiple URLs on the command line plus URLs from a file
EOF
}

# --- Args ---
INPUTS=()
while [[ $# -gt 0 ]]; do
  arg="$1"
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    -http|--http) DEFAULT_SCHEME="http"; shift ;;
    -https|--https) DEFAULT_SCHEME="https"; shift ;;
    -video|--video) MODE="video"; shift ;;
    -audio|--audio) MODE="audio"; shift ;;
    -images|--images) MODE="images"; shift ;;
    -pages|--pages) MODE="pages"; shift ;;
    -files|--files) MODE="files"; shift ;;
    -all|--all) MODE="all"; shift ;;
    -ext|--ext)
      [[ $# -ge 2 ]] || { echo "[!] --ext requires a value, e.g. --ext 'jpg|png|gif'"; exit 2; }
      EXT_PATTERN="$2"; shift 2 ;;
    -delay|--delay)
      [[ $# -ge 2 ]] || { echo "[!] --delay requires a value, e.g. --delay 0.9"; exit 2; }
      DELAY="$2"
      [[ "$DELAY" =~ ^[0-9]+([.][0-9]+)?$ ]] || { echo "[!] --delay must be a number, got: $DELAY"; exit 2; }
      shift 2 ;;
    -status-200|--status-200) STATUS_200=1; shift ;;
    -no-robots|--no-robots)   NO_ROBOTS=1;  shift ;;
    -sitemap-txt|--sitemap-txt) SITEMAP_TXT=1; shift ;;
    -sitemap-xml|--sitemap-xml) SITEMAP_XML=1; shift ;;
    --) shift; while [[ $# -gt 0 ]]; do INPUTS+=("$1"); shift; done; break ;;
    --*) echo "[!] Unknown option: $1"; usage; exit 2 ;;
    -*)  echo "[!] Unknown option: $1 (did you mean --${1#-} ?)"; usage; exit 2 ;;
    *) INPUTS+=("$1"); shift ;;
  esac
done

if [[ ${#INPUTS[@]} -eq 0 ]]; then
  echo "[!] No inputs provided." >&2
  usage; exit 1
fi

# Defaults per mode (unless --ext provided)
if [[ -z "$EXT_PATTERN" ]]; then
  case "$MODE" in
    video)  EXT_PATTERN='mp4|mkv|avi|mov|wmv|flv|webm|m4v|ogv|ts|m2ts' ;;
    audio)  EXT_PATTERN='mp3|mpa|mp2|aac|wav|flac|m4a|ogg|opus|wma|alac|aif|aiff' ;;
    images) EXT_PATTERN='jpg|jpeg|png|gif|webp|bmp|tiff|svg|avif|heic|heif' ;;
    pages)  EXT_PATTERN='html|htm|shtml|xhtml|php|phtml|asp|aspx|jsp|jspx|cfm|cgi|pl|do|action|md|markdown' ;;
    *)      EXT_PATTERN='' ;;  # files/all ignore unless user gave --ext
  esac
fi

# --- Temp & cleanup ---
TMP_INPUT="$(mktemp)"
TMP_URLS="$(mktemp)"
TMP_FIX="$(mktemp)"
cleanup() { rm -f "${TMP_INPUT}" "${TMP_URLS}" "${TMP_FIX}"; }
trap cleanup EXIT

# --- Collate inputs (files and/or literal URLs) ---
for src in "${INPUTS[@]}"; do
  if [[ -f "$src" ]]; then
    cat -- "$src" >> "${TMP_INPUT}"
  else
    printf '%s\n' "$src" >> "${TMP_INPUT}"
  fi
done

# --- Start fresh ---
: > "${LOG_FILE}"
: > "${OUTPUT_URLS}"

echo "[*] Normalizing start URLs (scheme: ${DEFAULT_SCHEME}; mode: ${MODE}; delay: ${DELAY}s; status-200: ${STATUS_200}; robots: $([[ $NO_ROBOTS -eq 1 ]] && echo off || echo on))"
SCHEME_PREFIX="${DEFAULT_SCHEME}://"

# A) Already-formed URLs
grep -Eo 'https?://[^[:space:]#]+' "${TMP_INPUT}" >> "${TMP_URLS}" || true

# B) Scheme-less -> add scheme (hostnames, IPv4, [IPv6], bare IPv6)
{ grep -Ev '^\s*(#|$)' "${TMP_INPUT}" \
  | grep -Ev '^\s*https?://' \
  | sed -E 's/\r$//' \
  | sed -E 's/^\s+|\s+$//g' \
  | awk -v P="$SCHEME_PREFIX" '
      /^\[[0-9A-Fa-f:]+\](:[0-9]+)?(\/.*)?$/     { print P $0; next }  # [IPv6]
      /^[0-9A-Fa-f:]+(\/.*)?$/ {
          match($0, /^([0-9A-Fa-f:]+)(\/.*)?$/, m)                     # bare IPv6
          host=m[1]; path=(m[2]?m[2]:""); print P "[" host "]" path; next
      }
      NF { print P $0 }                                                # host/IPv4
    ' >> "${TMP_URLS}"; } || true

# Add trailing slash to hosts and directory-like paths (no last-segment dot, no ? or #)
awk '
  {
    u=$0
    if (u ~ /[?#]/) { print u; next }
    if (u ~ /\/$/) { print u; next }
    if (u ~ "^https?://[^/]+$") { print u"/"; next }
    n=split(u,a,"/")
    last=a[n]
    if (index(last,".")==0) print u"/"; else print u
  }
' "${TMP_URLS}" > "${TMP_FIX}" && mv "${TMP_FIX}" "${TMP_URLS}"

# De-dup normalized start URLs
sort -u -o "${TMP_URLS}" "${TMP_URLS}"

if [[ ! -s "${TMP_URLS}" ]]; then
  echo "No valid URLs found (need full URLs or domain/IP entries)." >&2
  exit 2
fi

# --- Allowlist for wget (skip for IPv6 literal) ---
HOSTS="$(
  awk -F/ '/^https?:\/\//{print $3}' "${TMP_URLS}" \
  | sed -E 's/^\[([0-9A-Fa-f:]+)\](:[0-9]+)?$/\1/' \
  | sed -E 's/:[0-9]+$//' \
  | awk '{print tolower($0)}' \
  | sort -u
)"
HOSTS="$(echo "${HOSTS}" | awk '/^[a-z0-9-]+\.[a-z0-9-]+$/ {print; print "www."$0; next} {print}' | sort -u)"

USE_DOMAINS=1
if echo "${HOSTS}" | grep -q ':'; then USE_DOMAINS=0; fi

# --- Build wget command as an array ---
WGET_CMD=( wget --spider --recursive --no-parent --level=inf
           --no-directories --no-host-directories
           --wait="${DELAY}" --random-wait
           --no-verbose --output-file="${LOG_FILE}" )

# Respect robots by default; optionally ignore
if [[ "${NO_ROBOTS}" -eq 1 ]]; then
  WGET_CMD+=( -e robots=off )
fi

# Add status header printing if we need 200 filtering
if [[ "${STATUS_200}" -eq 1 ]]; then
  WGET_CMD+=( -S )
fi

# Domains allowlist (skip when IPv6 literal present)
if [[ ${USE_DOMAINS} -eq 1 ]]; then
  DOMAINS="$(echo "${HOSTS}" | paste -sd, -)"
  WGET_CMD+=( --domains="${DOMAINS}" )
fi

# Add input list
WGET_CMD+=( -i "${TMP_URLS}" )

echo "[*] Starting spider..."
[[ ${USE_DOMAINS} -eq 1 ]] && echo "[*] Domains allowlist: $(echo "${HOSTS}" | paste -sd, -)"
echo "[*] Logging to: ${LOG_FILE}"

# Run wget
"${WGET_CMD[@]}"

echo "[*] Extracting URLs from log..."

if [[ "${STATUS_200}" -eq 1 ]]; then
  # Keep only URLs that received HTTP 200 OK (handles same-line and next-line 200)
  awk '
    /URL:[[:space:]]*https?:\/\// {
      match($0, /URL:[[:space:]]*(https?:\/\/[^ ]+)/, m)
      u=m[1]; last=u
      if ($0 ~ /[[:space:]]200[[:space:]]+OK/) { print last; last="" }
      next
    }
    /HTTP\/[0-9.]+[[:space:]]+200/ && last { print last; last="" }
  ' "${LOG_FILE}" \
  | sed -E 's/[?#].*$//' \
  | sed -E 's#/(index\.html?)$#/#' \
  | sort -u > "${OUTPUT_URLS}"
else
  sed -nE 's/.*URL:[[:space:]]*(https?:\/\/[^ ]+).*/\1/p' "${LOG_FILE}" \
  | sed -E 's/[?#].*$//' \
  | sed -E 's#/(index\.html?)$#/#' \
  | sort -u > "${OUTPUT_URLS}"
fi

# --- Output filters ---
case "${MODE}" in
  video|audio|images)
    mv "${OUTPUT_URLS}" "${OUTPUT_URLS}.all"
    if [[ -n "$EXT_PATTERN" ]] && grep -Eiq "\.(${EXT_PATTERN})$" "${OUTPUT_URLS}.all"; then
      grep -Ei "\.(${EXT_PATTERN})$" "${OUTPUT_URLS}.all" > "${OUTPUT_URLS}"
    else
      : > "${OUTPUT_URLS}"
    fi
    rm -f "${OUTPUT_URLS}.all"
    echo "[*] Mode: ${MODE} only (ext: ${EXT_PATTERN})."
    ;;
  pages)
    mv "${OUTPUT_URLS}" "${OUTPUT_URLS}.all"
    # Keep directories OR page-like extensions
    awk -v IGNORECASE=1 -v PATS="${EXT_PATTERN}" '
      /\/$/ { print; next }
      $0 ~ "\\.(" PATS ")$" { print }
    ' "${OUTPUT_URLS}.all" | sort -u > "${OUTPUT_URLS}"
    rm -f "${OUTPUT_URLS}.all"
    echo "[*] Mode: pages only (dirs + ext: ${EXT_PATTERN})."
    ;;
  files)
    mv "${OUTPUT_URLS}" "${OUTPUT_URLS}.all"
    # All files = exclude directories and .html/.htm
    grep -Ev '(/$|\.html?$)' "${OUTPUT_URLS}.all" > "${OUTPUT_URLS}" || true
    rm -f "${OUTPUT_URLS}.all"
    echo "[*] Mode: all files (no dirs/pages)."
    ;;
  all)
    echo "[*] Mode: all URLs (dirs + pages + files)."
    ;;
esac

# --- Optional sitemaps ---
if [[ "${SITEMAP_TXT}" -eq 1 ]]; then
  cp "${OUTPUT_URLS}" sitemap.txt
  echo "[*] Wrote sitemap.txt"
fi

if [[ "${SITEMAP_XML}" -eq 1 ]]; then
  # Escape &, <, > for XML safety (queries/fragments already removed)
  esc() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }
  {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    while IFS= read -r u; do
      [[ -z "$u" ]] && continue
      echo "  <url><loc>$(printf '%s' "$u" | esc)</loc></url>"
    done < "${OUTPUT_URLS}"
    echo '</urlset>'
  } > sitemap.xml
  echo "[*] Wrote sitemap.xml"
fi

echo "[*] Done. Clean URLs written to: ${OUTPUT_URLS}"

