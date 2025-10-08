# Web Spider (Linux shell script)

A fast, polite, single-file Bash spider built around `wget --spider`.  
It takes one or more **start targets** (URLs, hostnames, IPv4/IPv6 — with optional ports), crawls **only the same domains** by default, and writes a clean, de-duplicated list of discovered URLs to `./urls`.

You can aim it at videos, audio, images, pages, **or everything**, and optionally emit a `sitemap.txt` and/or `sitemap.xml`.

---

## Features

- **Respectful by default** — honors `robots.txt` unless you opt out.
- **Same-site only** — strict allowlist built from your inputs, so it won’t wander off the domains you give it.
- **Smart normalization**  
  - Adds `https://` to scheme-less seeds (or use `--http` to default to HTTP).  
  - Adds trailing `/` to directory-like URLs (avoids `/dir → /dir/` redirect hiccups).  
  - Fully supports IPv6 (`[2001:db8::1]:8443`).
- **Flexible output modes**
  - `--video` (default), `--audio`, `--images`, `--pages`, `--files`, or `--all`.
  - `--ext 'pat|tern'` to override any preset (e.g., `pdf|docx|xlsx`).
- **Status filter** — `--status-200` keeps only URLs that returned **HTTP 200 OK**.
- **Polite pacing** — `--delay SECONDS` + `--random-wait` (default **0.5s**).
- **Sitemaps** — `--sitemap-txt` and/or `--sitemap-xml` from the **final filtered set**.
- **Robust log parsing** — handles both `URL: http://…` and `URL:http://…`.
- **Single-dash synonyms** — `-video`, `-images`, `-all`, `-ext`, `-delay`, etc.

---

## Requirements

- Bash (arrays & `set -euo pipefail` support; Bash 4+ recommended)
- `wget`, `awk`, `sed`, `grep`, `sort`, `mktemp`, `paste` (standard GNU userland)

---

## Installation

```bash
# Clone or copy the script into your PATH
git clone https://github.com/Pryodon/Web-Spider-Linux-shell-script.git
cd Web-Spider-Linux-shell-script
chmod +x webspider
# optional: symlink as 'spider'
ln -s "$PWD/webspider" ~/bin/spider
```

## Quick Start
```
# Crawl one site (video mode by default) and write results to ./urls
webspider https://www.example.com/

# Crawl one site searching only for .mkv and .mp4 files.
webspider --ext 'mkv|mp4' https://nyx.mynetblog.com/xc/

# Multiple seeds (scheme-less is OK; defaults to https)
webspider nyx.mynetblog.com www.mynetblog.com example.com

# From a file (one seed per line — URLs, hostnames, IPv4/IPv6 ok)
webspider seeds.txt
```

- Results:
  - `urls` — your filtered, unique URL list
  - `log` — verbose `wget` crawl log

By default the spider **respects robots**, stays on your domains, and returns **video files** only.

## Usage
```
webspider [--http|--https]
          [--video|--audio|--images|--pages|--files|--all]
          [--ext 'pat|tern'] [--delay SECONDS] [--status-200]
          [--no-robots]
          [--sitemap-txt] [--sitemap-xml]
          <links.txt | URL...>
```

### Modes (choose one; default is --video)
- `--video` : video files only
  - mp4|mkv|avi|mov|wmv|flv|webm|m4v|ts|m2ts
- `--audio` : audio files only
  - mp3|mpa|mp2|aac|wav|flac|m4a|ogg|opus|wma|alac|aif|aiff
- `--images` : image files only
  - jpg|jpeg|png|gif|webp|bmp|tiff|svg|avif|heic|heif
- `--pages` : directories (…/) + common page extensions
  - html|htm|shtml|xhtml|php|phtml|asp|aspx|jsp|jspx|cfm|cgi|pl|do|action|md|markdown
- `--files` : all files (excludes directories and .html? pages)
- `--all` : everything (directories + pages + files)

### Options
- `--ext` 'pat|tern' : override extension set used by --video/--audio/--images/--pages.
  - Example: --files --ext 'pdf|docx|xlsx'
- `--delay S` : polite crawl delay in seconds (default: 0.5), works with --random-wait
- `--status-200` : only keep URLs that returned HTTP 200 OK
- `--no-robots` : ignore robots.txt (default is to respect robots)
- `--http` | `--https` : default scheme for scheme-less seeds (default: --https)
- `-h` | `--help` : show usage

Single-dash forms work too: `-video`, `-images`, `-files`, `-all`, `-ext`, `-delay`, `-status-200`, `-no-robots`, etc.

## Examples
### 1) Video crawl (default), with strict 200 OK and slower pacing
`webspider --status-200 --delay 1.0 https://www.example.com/`

### 2) Images only, write a simple text sitemap
```
webspider --images --sitemap-txt https://www.example.com/
# Produces: urls  (images only)  and sitemap.txt (same set)
```

### 3) Pages-only crawl for a classic site sitemap
```
webspider --pages --sitemap-xml https://www.example.com/
# Produces sitemap.xml containing directories and page-like URLs
```

### 4) Plain HTTP on a high port (IPv4), custom extensions
`webspider --http --files --ext 'pdf|epub|zip' 192.168.1.50:8080`

### 5) Mixed seeds and a seed file
`webspider --audio nyx.mynetblog.com/xc seeds.txt https://www.mynetblog.com/`

### 6) IPv6 with port
`webspider --images https://[2001:db8::1]:8443/gallery/`

### 7) To partially mirror a website, you can use these commands for example...
```
webspider --files https://www.example.com/some/path/

wget --no-host-directories --force-directories --no-clobber --cut-dirs=0 -i urls
```

## What counts as a “seed”?

### You can pass:
- **Full URLs: `https://host/path`, `http://1.2.3.4:8080/dir/`**
- **Hostnames: `example.com`, `sub.example.com`**
- **IPv4: `10.0.0.5`, `10.0.0.5:8080/foo`**
- **IPv6: `[2001:db8::1]`, `[2001:db8::1]:8443/foo`**

### Normalization rules:
- If no scheme: prefix with the default (`https://`) or use `--http`
- If looks like a **directory** (no dot in last path segment, and no `?`/`#`): append `/`
- Domain allowlist is built from the seeds (auto-adds `www.` variant for bare domains, however there is a bug with this as it only lists the root page on the `www.` domain.)

<hr>

## What gets crawled?

- The spider runs `wget --spider --recursive --no-parent --level=inf` on your seed set.
- It **stays on the same domains** (via `--domains=<comma-list>`), unless a seed is an IP/IPv6 literal (then `--domains` is skipped, and `wget` still naturally sticks to that host).
- Extracts every `URL:` line from the `log` file, normalizes away query/fragments, dedupes, and then applies your mode filter<br/>
  (`--video/--audio/--images/--pages/--files/--all`).
- If `--status-200` is set, only URLs with an observed **HTTP 200 OK** are kept.

**Heads-up:** `wget --spider` generally uses **HEAD** requests where possible. Some servers don’t return 200 to HEAD even though GET would succeed. If filtering looks too strict, try without `--status-200`.

## Sitemaps
- `--sitemap-txt` → `sitemap.txt` (newline-delimited URLs)
- `--sitemap-xml` → `sitemap.xml` (Sitemaps.org format)

Both are generated from the **final filtered set** (`urls`).<br/>
For an SEO-style site map, use `--pages` (or `--all` if you really want everything).

## Performance & Politeness
- Default delay is `0.5` seconds with `--random-wait` to jitter requests.
- Tune with `--delay 1.0` (or higher) for shared hosts or when rate-limited.
- You can combine with `--status-200` to avoid collecting dead links.

Other knobs to consider (edit script if you want to hard-wire them):
- `--level=` to cap depth (the script currently uses `inf`)
- `--quota=` or `--reject=` patterns if you need to skip classes of files

## Security & Ethics
- Respect `robots.txt` (default). Only use `--no-robots` when you **own** the host(s) or have permission.
- Be mindful of server load and your network AUP. Increase `--delay` if unsure.

## Output Files
- `urls` — final, filtered, unique URLs (overwritten each run)
- `log` — full `wget` log (overwritten each run)
- Optional: `sitemap.txt`, `sitemap.xml` (when requested)

To keep results separate across runs, copy/rename `urls` or run the script in a different directory.<br/>
It is very easy to append the current list of urls to another file:<br/>
`cat urls >>biglist`

## Piping & Large seed sets
Passing a few dozen seeds on the command line is fine:<br/>
`webspider nyx.mynetblog.com www.mynetblog.com example.com`

For **very large** lists, avoid shell ARG_MAX limits:
```
# write to a file
generate_seeds > seeds.txt
webspider --images --status-200 seeds.txt

# or batch with xargs (runs webspider repeatedly with 100 seeds per call)
generate_seeds | xargs -r -n100 webspider --video --delay 0.8
```

## Troubleshooting

- **“Found no broken links.” but `urls` is empty**<br/>
  You likely hit `robots.txt` rules, or your mode filtered everything out.<br/>
  Try `--no-robots` (if permitted) and/or a different mode (e.g., `--all`).

- **Seeds without trailing slash don’t crawl**<br/>
  The script appends `/` to directory-like paths; if you still see issues, make sure redirects aren’t blocked upstream.

- `--status-200` drops too many<br/>
  Some servers don’t return 200 for HEAD. Re-run without `--status-200`.

- **IPv6 seeds**<br/>
  Always bracket: `https://[2001:db8::1]/`. The script helps, but explicit is best.

- **Off-site crawl**<br/>
  The allowlist comes from your seeds. If you seed `example.com`, it also allows `www.example.com`. (auto-adds `www.` variant for bare domains, however there is a bug with this as it only lists the root page on the `www.` domain.)<br/>
  If you see off-site URLs, confirm they truly share the same registrable domain, or seed more specifically (e.g., `sub.example.com/`).

<hr>

## FAQ

**Can I mix HTTP and HTTPS?**<br/>
Yes. Provide the scheme per-seed where needed, or use `--http` to default scheme-less seeds to HTTP.

**Will it download files?**<br/>
No. It runs `wget` in **spider mode** (HEAD/GET checks only), and outputs URLs to the `urls` file.
To actually download the files in the `urls` file, do something like this:<br/>
`wget -i urls`<br/>
Or..<br/>
`wget --no-host-directories --force-directories --no-clobber --cut-dirs=0 -i urls`

**Can I make a “pages + files” hybrid?**<br/>
Use `--all` (includes everything), or `--files --ext 'html|htm|php|…'` if you want file-only including page extensions.

**How do I only keep 200 OK pages in a search-engine sitemap?**<br/>
Use `--pages --status-200 --sitemap-xml`.


## Appendix: Preset extension lists
- Video: `mp4|mkv|avi|mov|wmv|flv|webm|m4v|ogv|ts|m2ts`
- Audio: `mp3|mpa|mp2|aac|wav|flac|m4a|ogg|opus|wma|alac|aif|aiff`
- Images: `jpg|jpeg|png|gif|webp|bmp|tiff|svg|avif|heic|heif`
- Pages: `html|htm|shtml|xhtml|php|phtml|asp|aspx|jsp|jspx|cfm|cgi|pl|do|action|md|markdown`

Override any of these with your own file extensions: `--ext 'pat|tern'`.

