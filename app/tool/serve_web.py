"""Serve the Flutter web build locally, like Netlify will.

Unknown paths (/home, /r/pizzeria-el-bahdja, ...) return index.html so
refreshing or opening a deep link works.

    python app/tool/serve_web.py            # http://localhost:8080
    python app/tool/serve_web.py 9000       # another port
"""

import functools
import http.server
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "build", "web")


class SpaHandler(http.server.SimpleHTTPRequestHandler):
    def send_head(self):
        path = self.translate_path(self.path)
        if not os.path.exists(path):
            self.path = "/index.html"
        return super().send_head()

    def end_headers(self):
        # Always fetch the newest build while developing.
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    if not os.path.exists(os.path.join(ROOT, "index.html")):
        sys.exit("No build found. Run: flutter build web --release "
                 "--dart-define-from-file=env.json (inside app/)")
    handler = functools.partial(SpaHandler, directory=ROOT)
    with http.server.ThreadingHTTPServer(("127.0.0.1", port), handler) as srv:
        print(f"Food App: http://localhost:{port}  (Ctrl+C to stop)", flush=True)
        srv.serve_forever()


if __name__ == "__main__":
    main()
