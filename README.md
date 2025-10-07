# Insanely Awesome Web Spider (Linux shell script)

**!!! This script requires the program [wget](https://www.gnu.org/software/wget/) !!!**

Spider start URLs/domains/IPs and produce a unique URL list that you can feed to wget for easy downloading.

This script uses the spidering functions of wget to mainly search web directories for media files but can also spider entire websites. It generates a list of URLs found and writes them to a file. The list of URLs can then be fed to wget for easy downloading.<br/>
`wget -i urls`

- This script honors website's robots.txt files but that can be disabled.
- There is a built-in crawl delay of 0.5 seconds. This can be adjusted to your needs.<br/>
`webspider --delay 1 www.example.com`<br/>
This will maintain a delay with jitter around 1 second between requests to the website.
- The script defaults to searching for video files but can also search for audio files, images, etc. or even search for your own file extensions that you provide.
- The script creates a list of URLs in a file named `urls` and a log file named `log`. These files will be placed in your current directory. These files are overwritten on each run of the script. You can easily append the current list of URLs to another file.<br/>
`cat urls >>biglist`

Some websites are found at IP addresses. The script defaults to using https but if your URL starts with `http://` it will work fine. If some targets must be http, include the scheme on those explicitly:<br/>
`webspider --files http://192.168.0.34:8080 https://www.example.com/`<br/>
This will spider those websites searching for all files but not web pages.

To partially mirror a website, you can use these commands...
```
webspider --all https://www.example.com/some/path/

wget --no-host-directories --force-directories --no-clobber --cut-dirs=0 -i urls
```
The script will only search under the `/some/path/` directory.

You can feed the script a file containing a list of URLs to spider:<br/>
`webspider --audio links.txt`<br/>
That would spider the websites in the file searching for audio files.

The script can even generate a sitemap text or XML file for your website!<br/>
`webspider --all --sitemap-xml https://www.example.com/`


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
    --pages    : directories (.../) + page-like extensions (html|htm|shtml|xhtml|php|phtml|asp|aspx|jsp|jspx|cfm|cgi|pl|do|action|md|markdown)
    --files    : all files (exclude directories and .html/.htm pages)
    --all      : everything (directories + pages + files)
 
  Options:
    --ext PAT       : override extension pattern used by --video/--audio/--images/--pages
                      Example: If you only want files with the extensions .abc and .xyz then use this command:
                      webspider --ext 'abc|xyz' https://www.example.com/
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
