#!/bin/bash

# USB Gadget Mode Toggle - Runtime version (NO REBOOT NEEDED)
# Called from Python/SamplePi app when top button is long-pressed.
# Toggles USB mass storage gadget on/off using kernel modules + configfs.

set -e

# Get the actual user even when run via sudo
CURRENT_USER="${SUDO_USER:-$(logname 2>/dev/null || whoami)}"
HOME_DIR=$(getent passwd "$CURRENT_USER" | cut -d: -f6)
STORAGE_IMG="$HOME_DIR/samplepi_media_storage.img"
MEDIA_DIR="$HOME_DIR/media"
GADGET_PATH="/sys/kernel/config/usb_gadget/samplepi"

LOG_FILE="/var/log/samplepi-gadget-toggle.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

is_gadget_active() {
    [ -d "$GADGET_PATH" ] && \
    [ -f "$GADGET_PATH/UDC" ] && \
    [ -s "$GADGET_PATH/UDC" ]
}

sync_to_image() {
    log "Syncing media files to storage image..."
    local TEMP_MOUNT
    TEMP_MOUNT=$(mktemp -d)
    if mount -o loop "$STORAGE_IMG" "$TEMP_MOUNT" 2>/dev/null; then
        mkdir -p "$TEMP_MOUNT/samples" "$TEMP_MOUNT/test_wavs"
        cp -ru "$MEDIA_DIR/samples/." "$TEMP_MOUNT/samples/" 2>/dev/null || true
        cp -ru "$MEDIA_DIR/test_wavs/." "$TEMP_MOUNT/test_wavs/" 2>/dev/null || true
        sync
        umount "$TEMP_MOUNT"
        log "Sync to image complete"
    else
        log "Warning: could not mount storage image for sync"
    fi
    rmdir "$TEMP_MOUNT" 2>/dev/null || true
}

sync_from_image() {
    log "Syncing files back from storage image..."
    local TEMP_MOUNT
    TEMP_MOUNT=$(mktemp -d)
    if mount -o loop "$STORAGE_IMG" "$TEMP_MOUNT" 2>/dev/null; then
        mkdir -p "$MEDIA_DIR/samples" "$MEDIA_DIR/test_wavs"
        cp -ru "$TEMP_MOUNT/samples/." "$MEDIA_DIR/samples/" 2>/dev/null || true
        cp -ru "$TEMP_MOUNT/test_wavs/." "$MEDIA_DIR/test_wavs/" 2>/dev/null || true
        umount "$TEMP_MOUNT"
        log "Sync from image complete"
    else
        log "Warning: could not mount storage image for sync"
    fi
    rmdir "$TEMP_MOUNT" 2>/dev/null || true
}

setup_gadget_configfs() {
    # Load dwc2 in peripheral mode if not already loaded
    if ! lsmod | grep -q "^dwc2 "; then
        log "Loading dwc2 driver..."
        modprobe dwc2
        sleep 1
    fi

    # Mount configfs if not already mounted
    if ! mountpoint -q /sys/kernel/config 2>/dev/null; then
        mount -t configfs none /sys/kernel/config
    fi

    # Bail out if gadget already configured
    if [ -d "$GADGET_PATH" ]; then
        log "Gadget configfs already present, binding to UDC..."
        ls /sys/class/udc | head -1 > "$GADGET_PATH/UDC"
        return 0
    fi

    log "Configuring USB gadget via configfs..."

    mkdir -p "$GADGET_PATH"
    echo 0x1d6b > "$GADGET_PATH/idVendor"
    echo 0x0104 > "$GADGET_PATH/idProduct"
    echo 0x0100 > "$GADGET_PATH/bcdDevice"
    echo 0x0200 > "$GADGET_PATH/bcdUSB"

    mkdir -p "$GADGET_PATH/strings/0x409"
    echo "SamplePi"                  > "$GADGET_PATH/strings/0x409/manufacturer"
    echo "SamplePi USB Mass Storage" > "$GADGET_PATH/strings/0x409/product"
    echo "SP123456789"               > "$GADGET_PATH/strings/0x409/serialnumber"

    mkdir -p "$GADGET_PATH/configs/c.1/strings/0x409"
    echo "SamplePi Config" > "$GADGET_PATH/configs/c.1/strings/0x409/configuration"
    echo 250               > "$GADGET_PATH/configs/c.1/MaxPower"

    mkdir -p "$GADGET_PATH/functions/mass_storage.usb0"
    echo "$STORAGE_IMG"          > "$GADGET_PATH/functions/mass_storage.usb0/lun.0/file"
    echo 1                       > "$GADGET_PATH/functions/mass_storage.usb0/lun.0/removable"
    echo "SamplePi Media Storage" > "$GADGET_PATH/functions/mass_storage.usb0/lun.0/inquiry_string"

    ln -s "$GADGET_PATH/functions/mass_storage.usb0" "$GADGET_PATH/configs/c.1/"

    # Bind to USB Device Controller
    ls /sys/class/udc | head -1 > "$GADGET_PATH/UDC"

    log "USB gadget bound to UDC"
}

teardown_gadget_configfs() {
    log "Tearing down USB gadget..."

    # Gracefully disconnect from host before removing
    echo "" > "$GADGET_PATH/UDC" 2>/dev/null || true
    sleep 2  # Give host time to notice disconnection

    # Remove function symlink from config
    rm -f "$GADGET_PATH/configs/c.1/mass_storage.usb0" 2>/dev/null || true

    # Remove config
    rmdir "$GADGET_PATH/configs/c.1/strings/0x409" 2>/dev/null || true
    rmdir "$GADGET_PATH/configs/c.1"               2>/dev/null || true

    # Remove function
    rmdir "$GADGET_PATH/functions/mass_storage.usb0" 2>/dev/null || true

    # Remove gadget strings and root
    rmdir "$GADGET_PATH/strings/0x409" 2>/dev/null || true
    rmdir "$GADGET_PATH"               2>/dev/null || true

    log "USB gadget torn down"
}

enable_gadget() {
    log "Enabling USB Gadget Mode (runtime)..."

    # Create storage image if not present
    if [ ! -f "$STORAGE_IMG" ]; then
        log "Creating storage image..."
        mkdir -p "$MEDIA_DIR/samples" "$MEDIA_DIR/test_wavs"
        local SIZE_MB
        SIZE_MB=$(( $(du -sm "$MEDIA_DIR" 2>/dev/null | cut -f1 || echo 50) + 100 ))
        dd if=/dev/zero of="$STORAGE_IMG" bs=1M count="$SIZE_MB" 2>/dev/null
        mkfs.vfat "$STORAGE_IMG" 2>/dev/null
        log "Storage image created (${SIZE_MB}MB)"
    fi

    sync_to_image
    setup_gadget_configfs
    log "USB Gadget Mode ENABLED - connect Pi to computer via USB"
}

disable_gadget() {
    log "Disabling USB Gadget Mode (runtime)..."
    teardown_gadget_configfs
    sync_from_image
    log "USB Gadget Mode DISABLED"
}

main() {
    log "========================================"
    log "USB Gadget Toggle"
    log "========================================"

    if is_gadget_active; then
        log "Current state: ENABLED -> Disabling"
        disable_gadget
    else
        log "Current state: DISABLED -> Enabling"
        enable_gadget
    fi
}

main
