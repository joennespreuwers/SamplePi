# DONE — 2026-03-25

## Bug fixes

- **`samplepi.service`** — added `Environment="MEDIA_PATH_TYPE=production"`. Without this the service was silently using `test_media/` instead of `/home/pi/media/` in production.
- **`install.sh`** — `git clone` now uses `--branch picoKeyboard`. Previously cloned `main`, deploying the wrong input configuration.

## Web upload server (`upload_server/`)

Flask app on port 8080 — browse to `http://<pi-ip>:8080` from any device on the local network.

- Drag-and-drop or file-picker upload for both **Test WAVs** and **Samples** categories
- Lists existing files with sizes; per-file delete button
- `.wav`-only validation on client and server; 500 MB max upload
- Runs as `samplepi-upload.service` (systemd, auto-enabled by `install.sh`)
- Dev: `python3 -m upload_server.server`

## USB auto-mount (`usb_mount/`)

Plug in a USB stick — WAV files are copied automatically, no interaction needed.

Expected USB layout:
```
/test_wavs/*.wav  →  /home/pi/media/test_wavs/
/samples/*.wav    →  /home/pi/media/samples/
/*.wav  (root)    →  /home/pi/media/test_wavs/   (fallback)
```

- **`99-samplepi-usb.rules`** — udev rule triggers on USB partition insertion
- **`samplepi-usb@.service`** — systemd template (oneshot, root); device name passed as instance
- **`usb_sync.sh`** — mounts read-only, copies, unmounts; logs to journald under tag `samplepi-usb`
- Monitor: `journalctl -f -t samplepi-usb`
- Installed automatically by `install.sh` (steps 10 & 11)

## Other

- `flask>=3.0.0` added to `requirements.txt`
- `rsync` added to apt deps in `install.sh`
- CLAUDE.md updated with file transfer docs and hardware test status table (Pico keycodes: **PASS**)
