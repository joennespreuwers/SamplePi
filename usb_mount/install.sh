#!/bin/bash
# Install USB auto-mount rules and service for SamplePi.
# Run once on the Raspberry Pi as a normal user (uses sudo internally).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/home/pi/SamplePi"   # must match samplepi-usb@.service ExecStart path

echo "=== SamplePi USB auto-mount installer ==="

# Make sync script executable
chmod +x "$SCRIPT_DIR/usb_sync.sh"

# Install udev rule
echo "[1/3] Installing udev rule..."
sudo cp "$SCRIPT_DIR/99-samplepi-usb.rules" /etc/udev/rules.d/
sudo udevadm control --reload-rules
echo "      Udev rules reloaded"

# Install systemd service template
echo "[2/3] Installing systemd service..."
sudo cp "$SCRIPT_DIR/samplepi-usb@.service" /etc/systemd/system/
sudo systemctl daemon-reload
echo "      Service template installed"

# Symlink sync script to expected location (in case repo is elsewhere)
if [ "$SCRIPT_DIR" != "$INSTALL_DIR/usb_mount" ]; then
    echo "[3/3] Note: repo is not at $INSTALL_DIR"
    echo "      Update ExecStart in samplepi-usb@.service to point to:"
    echo "      $SCRIPT_DIR/usb_sync.sh"
else
    echo "[3/3] Script path matches service — no changes needed"
fi

echo ""
echo "Done! Plug in a USB drive with .wav files to test."
echo "Monitor with: journalctl -f -t samplepi-usb"
echo ""
echo "Expected USB layout:"
echo "  /test_wavs/*.wav  →  /home/pi/media/test_wavs/"
echo "  /samples/*.wav    →  /home/pi/media/samples/"
echo "  /*.wav (root)     →  /home/pi/media/test_wavs/  (fallback)"
