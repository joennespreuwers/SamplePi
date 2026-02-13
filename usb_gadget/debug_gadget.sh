#!/bin/bash

# Debug script for SamplePi USB Gadget
# This script provides diagnostic information about the USB gadget status

echo "=== SamplePi USB Gadget Debug Information ==="

echo
echo "System Information:"
echo "  Hostname: $(hostname)"
echo "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"

echo
echo "USB Gadget Status:"
if [ -f "/sys/kernel/config/usb_gadget/samplepi/UDC" ]; then
    ACTIVE_CONTROLLER=$(cat /sys/kernel/config/usb_gadget/samplepi/UDC 2>/dev/null || echo "")
    if [ -n "$ACTIVE_CONTROLLER" ] && [ "$ACTIVE_CONTROLLER" != "" ]; then
        echo "  Status: ACTIVE"
        echo "  Controller: $ACTIVE_CONTROLLER"
    else
        echo "  Status: INACTIVE (configured but not enabled)"
    fi
else
    echo "  Status: NOT CONFIGURED"
fi

echo
echo "Media Directories:"
MEDIA_ROOT="/home/pi/media"
echo "  Main media dir: $MEDIA_ROOT"
echo "  Samples dir: $(if [ -d "$MEDIA_ROOT/samples" ]; then echo "EXISTS ($(ls -1 $MEDIA_ROOT/samples 2>/dev/null | wc -l) files)"; else echo "MISSING"; fi)"
echo "  Test WAVs dir: $(if [ -d "$MEDIA_ROOT/test_wavs" ]; then echo "EXISTS ($(ls -1 $MEDIA_ROOT/test_wavs 2>/dev/null | wc -l) files)"; else echo "MISSING"; fi)"

echo
echo "Storage Image:"
IMG_PATH="/home/pi/samplepi_media_storage.img"
if [ -f "$IMG_PATH" ]; then
    IMG_SIZE=$(du -h "$IMG_PATH" | cut -f1)
    echo "  Path: $IMG_PATH"
    echo "  Size: $IMG_SIZE"
    echo "  Status: EXISTS"
else
    echo "  Path: $IMG_PATH"
    echo "  Status: MISSING"
fi

echo
echo "SamplePi Process Status:"
if pgrep -f "samplepi.main\|MediaPlayer\|python.*samplepi" > /dev/null; then
    echo "  Status: RUNNING"
    ps aux | grep -E "(samplepi|MediaPlayer|python.*samplepi)" | grep -v grep
else
    echo "  Status: NOT RUNNING"
fi

echo
echo "Systemd Services:"
echo "  usb-gadget.service: $(systemctl is-active usb-gadget.service 2>/dev/null || echo "NOT FOUND")"
echo "  samplepi-gadget-sync.service: $(systemctl is-active samplepi-gadget-sync.service 2>/dev/null || echo "NOT FOUND")"

echo
echo "Mount Points:"
mount | grep samplepi || echo "No SamplePi mounts found"

echo
echo "Log File (last 10 lines):"
if [ -f "/var/log/samplepi-gadget-sync.log" ]; then
    tail -10 /var/log/samplepi-gadget-sync.log
else
    echo "Log file does not exist"
fi

echo
echo "=== Debug Information Complete ==="