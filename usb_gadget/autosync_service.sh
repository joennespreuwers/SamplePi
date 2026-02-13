#!/bin/bash

# USB Gadget Auto-sync Service for SamplePi
# This script monitors USB gadget connection status and syncs files automatically

LOG_FILE="/var/log/samplepi-gadget-sync.log"
MEDIA_ROOT="/home/pi/media"
GADGET_IMG="/home/pi/samplepi_media_storage.img"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to check if SamplePi is running
is_samplepi_running() {
    # Check for multiple possible process names to ensure we catch SamplePi
    if pgrep -f "samplepi.main\|MediaPlayer\|python.*samplepi" > /dev/null; then
        return 0  # SamplePi is running
    else
        return 1  # SamplePi is not running
    fi
}

# Function to sync gadget storage to main directories
sync_gadget_to_main() {
    if [ ! -f "$GADGET_IMG" ]; then
        log_message "Gadget image file not found: $GADGET_IMG"
        return 1
    fi

    log_message "Starting sync from gadget to main directories"

    # Create temporary mount point
    TEMP_MOUNT="/tmp/gadget_sync_$$"
    mkdir -p "$TEMP_MOUNT"

    # Mount the gadget image
    if mount -o loop "$GADGET_IMG" "$TEMP_MOUNT" 2>/dev/null; then
        # Sync samples directory
        if [ -d "$TEMP_MOUNT/samples" ]; then
            rsync -av --ignore-existing "$TEMP_MOUNT/samples/" "$MEDIA_ROOT/samples/" 2>>"$LOG_FILE"
            log_message "Samples synced from gadget"
        fi

        # Sync test_wavs directory
        if [ -d "$TEMP_MOUNT/test_wavs" ]; then
            rsync -av --ignore-existing "$TEMP_MOUNT/test_wavs/" "$MEDIA_ROOT/test_wavs/" 2>>"$LOG_FILE"
            log_message "Test WAVs synced from gadget"
        fi

        # Unmount
        umount "$TEMP_MOUNT" 2>>"$LOG_FILE"
        rmdir "$TEMP_MOUNT"

        log_message "Sync from gadget to main directories completed"
        return 0
    else
        log_message "Failed to mount gadget image for sync"
        rmdir "$TEMP_MOUNT"
        return 1
    fi
}

# Function to sync main directories to gadget storage
sync_main_to_gadget() {
    if [ ! -f "$GADGET_IMG" ]; then
        log_message "Gadget image file not found: $GADGET_IMG"
        return 1
    fi

    log_message "Starting sync from main directories to gadget"

    # Create temporary mount point
    TEMP_MOUNT="/tmp/gadget_sync_$$"
    mkdir -p "$TEMP_MOUNT"

    # Mount the gadget image
    if mount -o loop "$GADGET_IMG" "$TEMP_MOUNT" 2>/dev/null; then
        # Sync samples directory
        if [ -d "$MEDIA_ROOT/samples" ]; then
            rsync -av --ignore-existing "$MEDIA_ROOT/samples/" "$TEMP_MOUNT/samples/" 2>>"$LOG_FILE"
        fi

        # Sync test_wavs directory
        if [ -d "$MEDIA_ROOT/test_wavs" ]; then
            rsync -av --ignore-existing "$MEDIA_ROOT/test_wavs/" "$TEMP_MOUNT/test_wavs/" 2>>"$LOG_FILE"
        fi

        # Unmount
        umount "$TEMP_MOUNT" 2>>"$LOG_FILE"
        rmdir "$TEMP_MOUNT"

        log_message "Sync from main directories to gadget completed"
        return 0
    else
        log_message "Failed to mount gadget image for sync"
        rmdir "$TEMP_MOUNT"
        return 1
    fi
}

# Main logic based on command line argument
case "$1" in
    "startup")
        log_message "SamplePi USB Gadget Sync service starting"
        # When starting up, sync main to gadget to ensure gadget has latest files
        if ! is_samplepi_running; then
            sync_main_to_gadget
        else
            log_message "SamplePi is running, skipping initial sync"
        fi
        ;;
    "shutdown")
        log_message "SamplePi USB Gadget Sync service stopping"
        # When shutting down, sync gadget to main to preserve any new files
        if ! is_samplepi_running; then
            sync_gadget_to_main
        else
            log_message "SamplePi is running, skipping final sync"
        fi
        ;;
    "sync-to-main")
        log_message "Manual sync from gadget to main requested"
        if ! is_samplepi_running; then
            sync_gadget_to_main
        else
            log_message "SamplePi is running, skipping sync"
        fi
        ;;
    "sync-to-gadget")
        log_message "Manual sync from main to gadget requested"
        if ! is_samplepi_running; then
            sync_main_to_gadget
        else
            log_message "SamplePi is running, skipping sync"
        fi
        ;;
    *)
        echo "Usage: $0 {startup|shutdown|sync-to-main|sync-to-gadget}"
        exit 1
        ;;
esac