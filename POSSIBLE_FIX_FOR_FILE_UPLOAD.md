# Option B: HTTP File Server for File Transfer

## Overview

Instead of USB mass storage, the Pi runs a small HTTP server that lets any device
on the same network browse, download, and upload media files via a web browser.
No USB cable, no kernel modules, no reboots — just connect to a URL.

The Pi displays the URL (and optionally a QR code) on the touchscreen while the
server is running.

---

## How It Would Work

1. User long-presses TOP button (or selects from menu)
2. Pi starts an HTTP server on port 8080
3. Touchscreen shows the URL: `http://192.168.x.x:8080`
4. User opens that URL in a browser on any device on the same network
5. Browser shows a file manager: browse folders, download files, upload new files
6. User long-presses TOP button again to stop the server and return to normal

---

## Implementation Sketch

### Python HTTP server (Flask)

```python
# samplepi/file_server/server.py

from flask import Flask, request, send_from_directory, redirect, url_for
import os
import threading

app = Flask(__name__)
MEDIA_ROOT = None  # Set before starting

@app.route("/")
def index():
    return redirect(url_for("browse", path=""))

@app.route("/files/", defaults={"path": ""})
@app.route("/files/<path:path>")
def browse(path):
    full_path = os.path.join(MEDIA_ROOT, path)
    if os.path.isfile(full_path):
        return send_from_directory(MEDIA_ROOT, path, as_attachment=True)
    entries = os.listdir(full_path)
    # Render a minimal HTML file listing
    items = "".join(
        f'<li><a href="/files/{os.path.join(path, e)}">{e}</a></li>'
        for e in sorted(entries)
    )
    return f"""
    <html><body>
    <h2>SamplePi / {path or 'root'}</h2>
    <ul>{items}</ul>
    <hr>
    <form method="POST" action="/upload/{path}" enctype="multipart/form-data">
        <input type="file" name="file">
        <input type="submit" value="Upload">
    </form>
    </body></html>
    """

@app.route("/upload/", defaults={"path": ""}, methods=["POST"])
@app.route("/upload/<path:path>", methods=["POST"])
def upload(path):
    dest = os.path.join(MEDIA_ROOT, path)
    os.makedirs(dest, exist_ok=True)
    f = request.files["file"]
    f.save(os.path.join(dest, f.filename))
    return redirect(url_for("browse", path=path))


class FileServer:
    def __init__(self, media_root, port=8080):
        global MEDIA_ROOT
        MEDIA_ROOT = media_root
        self.port = port
        self._thread = None
        self._server = None

    def start(self):
        import werkzeug
        self._thread = threading.Thread(
            target=lambda: app.run(host="0.0.0.0", port=self.port),
            daemon=True
        )
        self._thread.start()

    def stop(self):
        # Flask dev server doesn't have a clean stop; for production use
        # waitress or a threading.Event + custom WSGI server.
        # Simplest approach: just restart the process or use os.kill on the thread.
        pass

    @property
    def url(self):
        import socket
        ip = socket.gethostbyname(socket.gethostname())
        return f"http://{ip}:{self.port}"
```

### UI screen (`samplepi/ui/screens/file_server_screen.py`)

```python
class FileServerScreen(Screen):
    def __init__(self, app, server):
        super().__init__(app)
        self.server = server

    def render(self):
        self.screen.fill(settings.COLOR_BACKGROUND)
        self.draw_text("FILE TRANSFER", 20, self.font_large, settings.COLOR_HIGHLIGHT)
        self.draw_text("Open in browser:", 70, self.font_small)
        self.draw_text(self.server.url, 95, self.font_medium, settings.COLOR_HIGHLIGHT)
        self.draw_text("/samples  /test_wavs", 130, self.font_small)
        self.draw_text("Hold TOP to stop server", 185, self.font_small, settings.COLOR_BUTTON_ACTIVE)
```

### Toggle in `main.py`

```python
def handle_file_server_toggle(self):
    if not hasattr(self, '_file_server'):
        from samplepi.file_server.server import FileServer
        from samplepi.config import settings
        self._file_server = FileServer(settings.MEDIA_ROOT)

    if self._file_server_running:
        self._file_server.stop()
        self._file_server_running = False
        self.state.goto_screen(StartScreen(self))
    else:
        self._file_server.start()
        self._file_server_running = True
        from samplepi.ui.screens.file_server_screen import FileServerScreen
        self.state.goto_screen(FileServerScreen(self, self._file_server))
```

---

## Dependencies

```
flask
# or for a production WSGI server (recommended over Flask dev server):
waitress
```

Install:
```bash
pip install flask waitress
```

---

## Pros vs USB Gadget (Option A)

| | Option A (USB Gadget) | Option B (HTTP Server) |
|---|---|---|
| Cable required | Yes (USB) | No |
| Network required | No | Yes (same WiFi/LAN) |
| Works offline | Yes | No |
| Browser needed on host | No | Yes |
| Drag-and-drop UX | Yes (Finder/Explorer) | In-browser only |
| Upload support | Yes | Yes (with Flask form) |
| Speed | Fast (USB 2.0) | Depends on WiFi |
| Complexity | Medium | Low |

## When to Use

Prefer Option B when:
- The Pi is connected to a known local network (lab WiFi or direct Ethernet)
- Multiple devices need to access files simultaneously
- No USB cable is available at the workstation

Prefer Option A when:
- The setup is isolated (no network)
- Users expect standard USB drive behaviour
- Network reliability is uncertain
