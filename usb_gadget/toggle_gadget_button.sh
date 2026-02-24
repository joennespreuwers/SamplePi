#!/bin/bash

# USB Gadget Mode Toggle - Non-Interactive Version
# Called from Python/SamplePi app when top button is long-pressed
# Automatically toggles gadget mode and reboots

set -e

GADGET_SERVICE="usb-gadget.service"
GADGET_SCRIPT="/usr/local/bin/configure_usb_gadget.sh"

# Get the actual (non-root) user when invoked via sudo
CURRENT_USER="${SUDO_USER:-$(logname 2>/dev/null || whoami)}"
HOME_DIR=$(getent passwd "$CURRENT_USER" | cut -d: -f6)
STORAGE_IMG="$HOME_DIR/samplepi_media_storage.img"
MEDIA_DIR="$HOME_DIR/media"

# Detect boot config location (Pi OS Bookworm uses /boot/firmware/)
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
    CMDLINE_FILE="/boot/firmware/cmdline.txt"
else
    CONFIG_FILE="/boot/config.txt"
    CMDLINE_FILE="/boot/cmdline.txt"
fi
CONFIG_BACKUP="${CONFIG_FILE}.backup"

LOG_FILE="/var/log/samplepi-gadget-toggle.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check current gadget mode status
is_gadget_mode() {
    if [ -d "/sys/kernel/config/usb_gadget/samplepi" ] && \
       [ -f "/sys/kernel/config/usb_gadget/samplepi/UDC" ] && \
       [ -s "/sys/kernel/config/usb_gadget/samplepi/UDC" ]; then
        return 0
    fi
    return 1
}

# Check if gadget service is enabled
is_gadget_service_enabled() {
    if systemctl is-enabled --quiet "$GADGET_SERVICE" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Backup config.txt
backup_config() {
    if [ ! -f "$CONFIG_BACKUP" ]; then
        cp "$CONFIG_FILE" "$CONFIG_BACKUP"
        log "Created backup of config.txt"
    fi
}

# Enable USB gadget mode
enable_gadget_mode() {
    log "Enabling USB Gadget Mode..."
    
    backup_config
    
    # Add dwc2 overlay if not present
    if ! grep -q "dtoverlay=dwc2" "$CONFIG_FILE"; then
        echo "dtoverlay=dwc2" >> "$CONFIG_FILE"
        log "Added dwc2 overlay to config.txt"
    fi
    
    # Add modules-load to cmdline.txt if not present
    if ! grep -q "modules-load=dwc2" "$CMDLINE_FILE"; then
        cp "$CMDLINE_FILE" "${CMDLINE_FILE}.backup"
        sed -i '1s/$/ modules-load=dwc2,g_mass_storage/' "$CMDLINE_FILE"
        log "Added modules-load to cmdline.txt"
    fi
    
    # Create storage image if it doesn't exist
    if [ ! -f "$STORAGE_IMG" ]; then
        log "Creating mass storage image..."
        
        mkdir -p "$MEDIA_DIR/samples" "$MEDIA_DIR/test_wavs"
        
        CURRENT_SIZE=$(du -sb "$MEDIA_DIR" 2>/dev/null | cut -f1 || echo "0")
        IMAGE_SIZE=$((CURRENT_SIZE + 100*1024*1024))
        IMAGE_SIZE_MB=$((IMAGE_SIZE / 1024 / 1024 + 100))
        
        dd if=/dev/zero of="$STORAGE_IMG" bs=1M count=$IMAGE_SIZE_MB 2>/dev/null
        mkfs.vfat "$STORAGE_IMG" 2>/dev/null
        
        # Copy existing media to image
        TEMP_MOUNT=$(mktemp -d)
        mount -o loop "$STORAGE_IMG" "$TEMP_MOUNT"
        cp -r "$MEDIA_DIR/samples" "$TEMP_MOUNT/" 2>/dev/null || true
        cp -r "$MEDIA_DIR/test_wavs" "$TEMP_MOUNT/" 2>/dev/null || true
        umount "$TEMP_MOUNT"
        rmdir "$TEMP_MOUNT"
        
        log "Mass storage image created (${IMAGE_SIZE_MB}MB)"
    fi
    
    # Create gadget script if it doesn't exist
    if [ ! -f "$GADGET_SCRIPT" ]; then
        log "Creating USB gadget configuration script..."
        cat > "$GADGET_SCRIPT" << 'GADGET_EOF'
#!/bin/bash
GADGET_PATH="/sys/kernel/config/usb_gadget/samplepi"
STORAGE_IMG="SAMPLEPI_HOME_DIR/samplepi_media_storage.img"

if [ -d "$GADGET_PATH" ]; then
    exit 0
fi

mkdir -p "$GADGET_PATH"
cd "$GADGET_PATH"

echo 0x1d6b > idVendor
echo 0x0104 > idProduct
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

mkdir -p strings/0x409
echo "SamplePi" > strings/0x409/manufacturer
echo "SamplePi USB Mass Storage" > strings/0x409/product
echo "SP123456789" > strings/0x409/serialnumber

mkdir -p configs/c.1/strings/0x409
echo "SamplePi Config" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower

mkdir -p functions/mass_storage.usb0
echo "$STORAGE_IMG" > functions/mass_storage.usb0/lun.0/file
echo 1 > functions/mass_storage.usb0/lun.0/removable
echo "SamplePi Media Storage" > functions/mass_storage.usb0/lun.0/inquiry_string

ln -s functions/mass_storage.usb0 configs/c.1/
ls /sys/class/udc > UDC

echo "USB Mass Storage Gadget enabled!"
GADGET_EOF
        sed -i "s|SAMPLEPI_HOME_DIR|${HOME_DIR}|g" "$GADGET_SCRIPT"
        chmod +x "$GADGET_SCRIPT"
    fi

    # Enable and start the gadget service
    systemctl enable "$GADGET_SERVICE" 2>/dev/null || true
    systemctl start "$GADGET_SERVICE" 2>/dev/null || true
    
    # Update SamplePi service
    MAIN_SERVICE="/etc/systemd/system/samplepi.service"
    if [ -f "$MAIN_SERVICE" ]; then
        if ! grep -q "MEDIA_PATH_TYPE=production" "$MAIN_SERVICE"; then
            sed -i '/\[Service\]/a Environment="MEDIA_PATH_TYPE=production"' "$MAIN_SERVICE"
            systemctl daemon-reload
        fi
    fi
    
    log "USB Gadget Mode ENABLED - Rebooting..."
    sleep 1
    reboot
}

# Disable USB gadget mode
disable_gadget_mode() {
    log "Disabling USB Gadget Mode..."
    
    # Stop the gadget
    if [ -f "/sys/kernel/config/usb_gadget/samplepi/UDC" ]; then
        echo "" > /sys/kernel/config/usb_gadget/samplepi/UDC 2>/dev/null || true
        log "Stopped USB gadget"
    fi
    
    # Disable the service
    systemctl stop "$GADGET_SERVICE" 2>/dev/null || true
    systemctl disable "$GADGET_SERVICE" 2>/dev/null || true
    
    # Remove dwc2 overlay from config.txt
    if grep -q "dtoverlay=dwc2" "$CONFIG_FILE"; then
        sed -i '/dtoverlay=dwc2/d' "$CONFIG_FILE"
        log "Removed dwc2 overlay from config.txt"
    fi
    
    # Remove modules-load from cmdline.txt
    if grep -q "modules-load=dwc2" "$CMDLINE_FILE"; then
        sed -i 's/ modules-load=dwc2,g_mass_storage//' "$CMDLINE_FILE"
        log "Removed modules-load from cmdline.txt"
    fi
    
    # Sync files from gadget storage
    if [ -f "$STORAGE_IMG" ]; then
        log "Syncing files from gadget storage..."
        TEMP_MOUNT=$(mktemp -d)
        if mount -o loop "$STORAGE_IMG" "$TEMP_MOUNT" 2>/dev/null; then
            if [ -d "$TEMP_MOUNT/samples" ]; then
                cp -ru "$TEMP_MOUNT/samples/" "$MEDIA_DIR/samples/" 2>/dev/null || true
            fi
            if [ -d "$TEMP_MOUNT/test_wavs" ]; then
                cp -ru "$TEMP_MOUNT/test_wavs/" "$MEDIA_DIR/test_wavs/" 2>/dev/null || true
            fi
            umount "$TEMP_MOUNT" 2>/dev/null || true
            log "Files synced successfully"
        fi
        rmdir "$TEMP_MOUNT" 2>/dev/null || true
    fi
    
    log "USB Gadget Mode DISABLED - Rebooting..."
    sleep 1
    reboot
}

# Main
main() {
    log "========================================"
    log "USB Gadget Toggle Triggered"
    log "========================================"
    
    if is_gadget_service_enabled || is_gadget_mode; then
        log "Current state: Gadget Mode ENABLED"
        disable_gadget_mode
    else
        log "Current state: Gadget Mode DISABLED"
        enable_gadget_mode
    fi
}

main
