# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Active Branch

Currently working on **`fb-direct`** — branched from `picoKeyboard`. Same Pico USB-HID input, but the display is driven directly via SDL's `fbcon` framebuffer driver instead of X11, so the Pi can boot straight to the app with no desktop session. Do not merge or pull from `usb-gadget-mode`.

## Project Purpose

Python app that runs on a Raspberry Pi 4 (Raspbian Lite, no desktop required). Plays sequences of WAV files through a HiFiBerry DAC Pro XLR and fires a 100ms GPIO pulse on camera trigger pin to sync audio playback with an external video recorder.

## Dev Commands

```bash
# Setup
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python3 create_test_files.py   # generate test WAV files

# Run (desktop/dev)
python3 -m samplepi.main

# Run (production mode, uses /home/pi/media)
MEDIA_PATH_TYPE=production python3 -m samplepi.main

# Deploy to Pi
bash install.sh                # full install + systemd service
sudo systemctl status samplepi
sudo journalctl -u samplepi -f
```

## Architecture

### Input Flow (picoKeyboard branch)
```
Rotary Encoder → Pico (USB HID) → RPi4 USB → pygame KEYDOWN events
                                               ↑↓ = scroll, ENTER = select, L = long press

Single GPIO button (GPIO 6) → gpiozero → long press callback
```
The Pico firmware is pre-compiled: `rotary_encoder_keyboard/build/*.uf2`. Flash by holding BOOTSEL, plugging USB, then drag-dropping the `.uf2` onto the RPI-RP2 drive.

### Application Structure
- `samplepi/main.py` — entry point, pygame loop, keyboard/mouse event routing
- `samplepi/state/app_state.py` — screen stack (`goto_screen`, `go_back`, `go_home`), user selections, playback flags
- `samplepi/audio/player.py` — pygame.mixer sequential WAV playback; pause does NOT re-trigger camera
- `samplepi/gpio/rotary.py` — gpiozero rotary encoder + long-press detection via threading.Timer
- `samplepi/gpio/camera.py` — 100ms HIGH pulse on GPIO 26 at playback start
- `samplepi/gpio/touchscreen.py` — single long-press button (GPIO 6); legacy 3-button methods are no-ops
- `samplepi/ui/screens/` — screen stack: `StartScreen → FileSelection (×2) → RecordingToggle → Confirm → Playback → Complete`
- `samplepi/config/settings.py` — all GPIO pins, display size, colors, paths

### GPIO Pins (picoKeyboard branch)
| Signal | Pin |
|--------|-----|
| Rotary CLK | GPIO 12 (on Pico, not RPi) |
| Rotary DT | GPIO 13 (on Pico, not RPi) |
| Rotary SW | GPIO 16 (on Pico, not RPi) |
| Long-press button | GPIO 6 (RPi direct) |
| Camera trigger | GPIO 26 |

### Touch Status
**XPT2046 touch is disabled** in this branch. Run `disable_touch.sh` on the Pi to blacklist the driver. The `touchscreen.py` only wires up the single long-press GPIO button — all other button callbacks are no-ops. Mouse events from pygame are still routed to `screen.handle_input()` but no physical touch input is connected.

### Display: direct framebuffer (fb-direct branch)
No X11, no window manager, no desktop autostart. `samplepi/main.py::configure_display_driver()` sets `SDL_VIDEODRIVER=fbcon` and `SDL_FBDEV` (from `settings.FRAMEBUFFER_DEVICE`, default `/dev/fb1`) before `pygame.init()`, but only when `DISPLAY` is unset — so dev on Mac/X11 is unaffected.

- `settings.FRAMEBUFFER_DEVICE` — override with `SAMPLEPI_FBDEV` env var if the Waveshare LCD enumerates as a different `/dev/fbN`.
- The old manual mmap-based `samplepi/framebuffer.py` blitter (unused, from an earlier abandoned attempt) was removed — SDL's `fbcon` driver handles the blit/format conversion now.
- `samplepi.service` runs on `/dev/tty1` (`TTYPath`, `StandardInput=tty`) so SDL's fbcon driver can own the VT (cursor blanking) and read input from `/dev/input/event*`. Targets `multi-user.target`, no `graphical.target` dependency.
- `install.sh` adds the service user to the `video`, `input`, `tty`, `render` groups instead of configuring X11/`fbturbo`/auto-login/startx.

**Not yet verified on hardware:** whether `fbcon` renders correctly (color order/rotation) on the Waveshare 3.2" `waveshare32b` overlay, and whether the Pico's USB-HID keyboard events reach SDL via fbcon's evdev input. If `fbcon` has issues with this panel, `kmsdrm` (for DRM/tinydrm-based panel drivers) is the other option to try.

### Deployment & Service
`install.sh` handles full Pi setup: apt deps, Waveshare LCD driver, HiFiBerry config, venv, group permissions, and systemd service. The service file `samplepi.service` has `%USER%`/`%HOME%` placeholders that `install.sh` substitutes at install time.

Production media lives at `/home/pi/media/{test_wavs,samples}/`.

## Branch Map

| Branch | Input method | Display |
|--------|-------------|---------|
| `main` | GPIO direct (17/27/22) | X11 |
| `picoKeyboard` | Pico USB HID | X11 (auto-login + startx) |
| `fb-direct` | Pico USB HID | Direct framebuffer (`fbcon`, no X11) |
| `usb-gadget-mode` | Pico USB HID | X11, plus USB gadget (long-press toggle) |
| `sidd` | GPIO direct | X11 |

## File Transfer

Two mechanisms for getting WAV files onto the Pi:

### Web upload server (`upload_server/`)
Flask app on port 8080. Browser UI with drag-and-drop upload zones for each category.
```bash
# Dev
python3 -m upload_server.server

# On Pi — runs as systemd service automatically after install
sudo systemctl status samplepi-upload
sudo journalctl -u samplepi-upload -f
```
Endpoints: `GET /api/files/<category>`, `POST /api/upload/<category>`, `DELETE /api/files/<category>/<filename>`.
Categories: `test_wavs`, `samples`.

### USB auto-mount (`usb_mount/`)
udev rule (`99-samplepi-usb.rules`) fires `samplepi-usb@<device>.service` on USB partition insertion.
Service runs `usb_sync.sh <device>` as root, which mounts read-only, copies WAVs, and unmounts.

Expected USB layout:
```
/test_wavs/*.wav  →  /home/pi/media/test_wavs/
/samples/*.wav    →  /home/pi/media/samples/
/*.wav  (root)    →  /home/pi/media/test_wavs/   (fallback)
```
Monitor: `journalctl -f -t samplepi-usb`

### Install both
The main `install.sh` installs both automatically (steps 10 and 11). To install standalone: `bash usb_mount/install.sh`.

## Testing Status

| Test | Status |
|------|--------|
| Pico sends correct keycodes (↑↓ Enter L) | **PASS** |
| Direct framebuffer (`fbcon`) renders correctly on Waveshare LCD | pending |
| Pico keyboard input received via fbcon (no X11) | pending |
| Audio plays through HiFiBerry | pending |
| Camera trigger 100ms pulse | pending |
| Pause does not re-trigger camera | pending |
| Sequential file playback | pending |
| Web upload server | pending |
| USB auto-mount | pending |
