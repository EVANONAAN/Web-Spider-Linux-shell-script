Spider start URLs/domains/IPs and produce a unique URL list that you can feed to wget for easy downloading.

**!!! This script requires the program [wget](https://www.gnu.org/software/wget/) !!!**

<pre>
Usage:
    webspider [--http|--https]
              [--video|--audio|--images|--pages|--files|--all]
              [--ext 'pat|tern'] [--delay SECONDS] [--status-200]
              [--no-robots]
              [--sitemap-txt] [--sitemap-xml]
              <links.txt | URL...>
 
  Modes (choose one; default is --video):
    --video    : video files only (mp4|mkv|avi|mov|wmv|flv|webm|m4v|ts|m2ts)
    --audio    : audio files only (mp3|mpa|mp2|aac|wav|flac|m4a|ogg|opus|wma|alac|aif|aiff)
    --images   : image files only (jpg|jpeg|png|gif|webp|bmp|tiff|svg|avif|heic|heif)
    --pages    : directories (â€¦/) + page-like extensions (html|htm|shtml|xhtml|php|phtml|asp|aspx|jsp|jspx|cfm|cgi|pl|do|action|md|markdown)
    --files    : all files (exclude directories and .html/.htm pages)
    --all      : everything (dirs + pages + files)
 
  Options:
    --ext PAT       : override extension pattern used by --video/--audio/--images/--pages
    --delay S       : polite crawl delay in seconds (default: 0.5). Accepts decimals. Uses wget --wait + --random-wait.
    --status-200    : only keep URLs that returned HTTP 200 OK (adds -S to wget and parses statuses)
    --no-robots     : ignore robots.txt (default: respect robots)
    --sitemap-txt   : write sitemap.txt (plain newline-separated list of final URLs)
    --sitemap-xml   : write sitemap.xml (Sitemaps.org XML from final URLs)
    --http|--https  : default scheme for scheme-less inputs (default: https)
    -h, --help      : show this help
 
- Notes:
   - Single-dash forms work too: -video, -audio, -images, -pages, -files, -all, -ext, -delay, -status-200, -no-robots, -sitemap-txt, -sitemap-xml
   - Use -- to end options if a path starts with a dash.
</pre>
