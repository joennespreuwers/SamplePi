# Manual Flashing Instructions

The compiled UF2 file is ready at: `build/rotary_encoder_keyboard.ino.uf2`

## Steps to Flash Manually:

1. **Put your Pico into bootloader mode:**
   - Disconnect the USB cable from your Pico
   - Hold down the **BOOTSEL button** on the Pico (the white button on the board)
   - While holding BOOTSEL, plug the USB cable back in
   - Release the BOOTSEL button
   - The Pico should appear as a USB drive named "RPI-RP2"

2. **Copy the UF2 file:**
   - Simply drag and drop `build/rotary_encoder_keyboard.ino.uf2` to the RPI-RP2 drive
   - Or use this command:
     ```
     cp build/rotary_encoder_keyboard.ino.uf2 /Volumes/RPI-RP2/
     ```

3. **The Pico will automatically:**
   - Flash the firmware
   - Reboot
   - Disconnect the RPI-RP2 drive
   - Start running as a USB keyboard

## Verification:

Once flashed, the Pico will act as a keyboard. You can test it by:
- Opening a text editor
- Rotating the encoder (should type up/down arrows)
- Pressing the button (should type Enter or 'L')

## Troubleshooting:

If the RPI-RP2 drive doesn't appear:
- Make sure you're holding BOOTSEL before plugging in USB
- Try a different USB cable or port
- Check that the Pico's LED lights up when connected
