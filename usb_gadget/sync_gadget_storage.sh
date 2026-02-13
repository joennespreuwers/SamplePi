#!/bin/bash

# Synchronization script for SamplePi USB Gadget
# This script copies files from the USB gadget storage back to the main media directories
# when the gadget is disconnected

set -e

MEDIA_ROOT="/home/pi/media"
SAMPLES_DIR="$MEDIA_ROOT/samples"
TEST_WAVS_DIR="$MEDIA_ROOT/test_wavs"
GADGET_IMG="/home/pi/samplepi_media_storage.img"

# Function to check if SamplePi is running
is_samplepi_running() {
    # Check for multiple possible process names to ensure we catch SamplePi
    if pgrep -f "samplepi.main\|MediaPlayer\|python.*samplepi" > /dev/null; then
        return 0  # SamplePi is running
    else
        return 1  # SamplePi is not running
    fi
}

# Function to sync gadget storage back to main directories
sync_from_gadget() {
    # Check if SamplePi is running before proceeding
    if is_samplepi_running; then
        echo "ERROR: SamplePi is currently running. Please stop it before syncing."
        exit 1
    fi

    echo "Syncing files from USB gadget storage to main directories..."

    # Create temporary mount point
    TEMP_MOUNT="/tmp/gadget_sync"
    sudo mkdir -p "$TEMP_MOUNT"

    # Mount the gadget image
    sudo mount -o loop "$GADGET_IMG" "$TEMP_MOUNT"

    # Sync samples directory (copy new/updated files from gadget to main)
    if [ -d "$TEMP_MOUNT/samples" ]; then
        rsync -av --ignore-existing "$TEMP_MOUNT/samples/" "$SAMPLES_DIR/"
        echo "Samples synced"
    fi

    # Sync test_wavs directory
    if [ -d "$TEMP_MOUNT/test_wavs" ]; then
        rsync -av --ignore-existing "$TEMP_MOUNT/test_wavs/" "$TEST_WAVS_DIR/"
        echo "Test WAVs synced"
    fi

    # Unmount and clean up
    sudo umount "$TEMP_MOUNT"
    sudo rmdir "$TEMP_MOUNT"

    echo "Sync complete!"
}

# Function to sync main directories to gadget storage
sync_to_gadget() {
    # Check if SamplePi is running before proceeding
    if is_samplepi_running; then
        echo "ERROR: SamplePi is currently running. Please stop it before syncing."
        exit 1
    fi

    echo "Syncing files from main directories to USB gadget storage..."

    # Create temporary mount point
    TEMP_MOUNT="/tmp/gadget_sync"
    sudo mkdir -p "$TEMP_MOUNT"

    # Mount the gadget image
    sudo mount -o loop "$GADGET_IMG" "$TEMP_MOUNT"

    # Sync samples directory
    if [ -d "$SAMPLES_DIR" ]; then
        rsync -av --ignore-existing "$SAMPLES_DIR/" "$TEMP_MOUNT/samples/"
    fi

    # Sync test_wavs directory
    if [ -d "$TEST_WAVS_DIR" ]; then
        rsync -av --ignore-existing "$TEST_WAVS_DIR/" "$TEMP_MOUNT/test_wavs/"
    fi

    # Unmount and clean up
    sudo umount "$TEMP_MOUNT"
    sudo rmdir "$TEMP_MOUNT"

    echo "Initial sync to gadget complete!"
}

# Function to check if gadget is currently active
is_gadget_active() {
    if [ -f "/sys/kernel/config/usb_gadget/samplepi/UDC" ]; then
        ACTIVE_CONTROLLER=$(cat /sys/kernel/config/usb_gadget/samplepi/UDC 2>/dev/null || echo "")
        if [ -n "$ACTIVE_CONTROLLER" ] && [ "$ACTIVE_CONTROLLER" != "" ]; then
            return 0  # Gadget is active
        fi
    fi
    return 1  # Gadget is not active
}

# Main logic
case "$1" in
    "to-gadget")
        sync_to_gadget
        ;;
    "from-gadget")
        sync_from_gadget
        ;;
    "check-status")
        if is_gadget_active; then
            echo "USB Gadget is ACTIVE"
            exit 0
        else
            echo "USB Gadget is INACTIVE"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {to-gadget|from-gadget|check-status}"
        echo "  to-gadget    : Sync main directories to gadget storage"
        echo "  from-gadget  : Sync gadget storage to main directories"
        echo "  check-status : Check if gadget is currently active"
        exit 1
        ;;
esac