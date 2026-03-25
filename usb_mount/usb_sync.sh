#!/bin/bash
# Mounts a USB storage partition and copies WAV files into the SamplePi media dirs.
#
# Usage: usb_sync.sh <device>   e.g. usb_sync.sh sda1
#
# Folder layout expected on the USB drive:
#   test_wavs/*.wav  → /home/pi/media/test_wavs/
#   samples/*.wav    → /home/pi/media/samples/
#   *.wav (root)     → /home/pi/media/test_wavs/   (fallback)
#
# Files are never deleted from the Pi; new files are added, existing are overwritten.

set -euo pipefail

DEVICE="${1:-}"
if [ -z "$DEVICE" ]; then
    echo "Usage: $0 <device>  (e.g. sda1)" >&2
    exit 1
fi

MOUNT_POINT="/mnt/samplepi-usb"
MEDIA_ROOT="/home/pi/media"
TEST_WAVS_DIR="$MEDIA_ROOT/test_wavs"
SAMPLES_DIR="$MEDIA_ROOT/samples"
LOG_TAG="samplepi-usb"

log() { logger -t "$LOG_TAG" "$*"; echo "$*"; }

# Verify device exists
if [ ! -b "/dev/$DEVICE" ]; then
    log "ERROR: /dev/$DEVICE is not a block device"
    exit 1
fi

# Create mount point and media dirs
mkdir -p "$MOUNT_POINT" "$TEST_WAVS_DIR" "$SAMPLES_DIR"

# Mount (read-only is fine)
if mountpoint -q "$MOUNT_POINT"; then
    log "WARNING: $MOUNT_POINT already mounted, unmounting first"
    umount "$MOUNT_POINT" || true
fi

log "Mounting /dev/$DEVICE → $MOUNT_POINT"
mount -o ro "/dev/$DEVICE" "$MOUNT_POINT"

# ── sync helper ──────────────────────────────────────────────────────────────
copied=0
sync_wavs() {
    local src="$1"
    local dst="$2"
    if [ ! -d "$src" ]; then return; fi
    shopt -s nullglob
    for f in "$src"/*.wav "$src"/*.WAV; do
        [ -f "$f" ] || continue
        name="$(basename "$f")"
        log "  Copying $name → $dst/"
        cp "$f" "$dst/$name"
        copied=$((copied + 1))
    done
    shopt -u nullglob
}

# ── copy test_wavs ────────────────────────────────────────────────────────────
sync_wavs "$MOUNT_POINT/test_wavs" "$TEST_WAVS_DIR"
sync_wavs "$MOUNT_POINT/Test_WAVs" "$TEST_WAVS_DIR"   # tolerate capitalisation

# ── copy samples ──────────────────────────────────────────────────────────────
sync_wavs "$MOUNT_POINT/samples"   "$SAMPLES_DIR"
sync_wavs "$MOUNT_POINT/Samples"   "$SAMPLES_DIR"

# ── fallback: WAVs in USB root → test_wavs ────────────────────────────────────
shopt -s nullglob
for f in "$MOUNT_POINT"/*.wav "$MOUNT_POINT"/*.WAV; do
    [ -f "$f" ] || continue
    name="$(basename "$f")"
    log "  (root) Copying $name → $TEST_WAVS_DIR/"
    cp "$f" "$TEST_WAVS_DIR/$name"
    copied=$((copied + 1))
done
shopt -u nullglob

log "Done — $copied file(s) copied"

# ── unmount ───────────────────────────────────────────────────────────────────
sync
umount "$MOUNT_POINT"
log "Unmounted /dev/$DEVICE"
