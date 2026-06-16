# SamplePi USB Gadget Mode

This configuration allows the SamplePi to appear as a USB mass storage device when connected to a computer, making it easy to add and manage audio samples.

## Overview

When enabled, the Raspberry Pi will appear as a USB drive when connected to a computer via USB. This allows for easy file management of audio samples without needing network connectivity or SSH access.

## Features

- Appears as a standard USB mass storage device to any computer
- Contains organized directories for samples and test WAV files
- Preserves existing media when reconnecting
- Safe eject functionality to prevent data corruption

## Setup

1. Run the setup script on your Raspberry Pi:
   ```bash
   chmod +x usb_gadget/setup_usb_gadget.sh
   ./usb_gadget/setup_usb_gadget.sh
   ```

2. Reboot the Raspberry Pi:
   ```bash
   sudo reboot
   ```

3. After reboot, connect the Pi to your computer via USB

## Usage

### Adding Samples
1. Connect the Pi to your computer via USB
2. The Pi will appear as a USB drive named "SamplePi Media Storage"
3. Copy your WAV files to the appropriate directories:
   - `samples/` - For your custom samples
   - `test_wavs/` - For test WAV files
4. Safely eject the drive from your computer

### Safe Removal
To safely disconnect the Pi from the host computer:
```bash
sudo /usr/local/bin/eject_usb_gadget.sh
```

This ensures all data is properly written before disconnection.

## Technical Details

- Creates a virtual storage device using the Linux USB Gadget framework
- Uses a disk image file to store the media files
- Automatically synchronizes changes back to the main media directories
- Configured as a mass storage device (USB MSC) for universal compatibility
- Works with the production configuration of SamplePi that uses `/home/pi/media` as the media directory

## Limitations

- While in gadget mode, the Pi cannot access the media directories directly
- The SamplePi application should not be running when managing files via USB
- Requires a reboot to enable the USB gadget functionality
- Only one USB device function can be active at a time

## Troubleshooting

### Pi doesn't appear as USB drive
- Ensure you're using the USB port capable of OTG (usually the power port on Pi Zero)
- Check that the Pi has fully booted after reboot
- Verify the USB cable supports data transfer (not just power)

### Cannot write to the drive
- The drive might be mounted as read-only due to file system errors
- Try safely ejecting and reconnecting
- Run fsck on the image file if problems persist

### Files don't appear in SamplePi application
- Ensure the USB gadget is disconnected before running SamplePi
- The media directories are only synchronized when the gadget is disabled