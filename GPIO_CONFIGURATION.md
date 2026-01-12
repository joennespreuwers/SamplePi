# GPIO Pin Configuration for SamplePi

## Overview
This document describes the GPIO pin configuration for SamplePi to avoid conflicts between the display, touch controller, and input devices.

## Pin Conflicts and Safe Assignments

### SPI Display (Waveshare 3.2" LCD) Uses:
- GPIO 10 (MOSI)
- GPIO 11 (SCLK)
- GPIO 8 (CE0)
- GPIO 7 (CE1)
- GPIO 9 (MISO) - sometimes used
- GPIO 25 (DC) - sometimes used for display control
- GPIO 18 (RST) - sometimes used for display reset

### XPT2046 Touch Controller Uses:
- GPIO 17 (IRQ/T_CS) - interrupt pin
- GPIO 23 (DIN) - touch data in
- GPIO 24 (DOUT) - touch data out
- GPIO 27 (CLK) - touch clock
- GPIO 22 (CS) - chip select

### Previously Used (Conflicting) Pins:
- GPIO 17 - Rotary CLK (CONFLICT with touch IRQ)
- GPIO 27 - Rotary DT (CONFLICT with touch CLK)
- GPIO 22 - Rotary SW (CONFLICT with touch CS)
- GPIO 13 - Bottom button (CONFLICT with touch possible)

### Newly Assigned Safe Pins:
- GPIO 12 - Rotary CLK (PWM0 - safe)
- GPIO 13 - Rotary DT (PWM1 - safe)
- GPIO 16 - Rotary SW (integrated push button) (CE2 - safe)

### Physical Buttons (Left Side - separate from rotary encoder):
- Top Button → GPIO 5 (Pin 29)
- Middle Button → GPIO 6 (Pin 31)
- Bottom Button → GPIO 19 (Pin 35)

## Recommended Wiring

### Rotary Encoder (5-pin with integrated push button) Connections:
- VCC → 3.3V (Pin 1)
- GND → Ground (Pin 6 or 9 or 14 or 20 or 25 or 30 or 34 or 39)
- CLK → GPIO 12 (Pin 32)
- DT → GPIO 13 (Pin 33)
- SW → GPIO 16 (Pin 36) (integrated push button)

### Optional Physical Buttons (Left Side - separate from rotary encoder):
If you have additional physical buttons on the left side of the display (separate from the rotary encoder's push button):
- Top Button → GPIO 5 (Pin 29)
- Middle Button → GPIO 6 (Pin 31)
- Bottom Button → GPIO 19 (Pin 35)

Note: The rotary encoder's integrated push button serves as the main selection button, so the separate physical buttons may be redundant depending on your UI preferences.

### Camera Trigger:
- Camera Trigger → GPIO 26 (Pin 37)

## Pin Layout Reference (BCM Numbering)

```
GPIO Pin Layout (Top to Bottom, Physical Pin Numbers):

         3.3V  1  |  2  5V
    GPIO  2  3  |  4  5V
    GPIO  3  5  |  6  GND
    GPIO  4  7  |  8  GPIO 14 (TXD)
        GND  9  | 10  GPIO 15 (RXD)
    GPIO 17 11  | 12  GPIO 18 (PCM_CLK)
    GPIO 27 13  | 14  GND
    GPIO 22 15  | 16  GPIO 23
         3.3V 17  | 18  GPIO 24
    GPIO 10 19  | 20  GND
    GPIO  9 21  | 22  GPIO 25
    GPIO 11 23  | 24  GPIO 8 (SPI_CE0_N)
        GND 25  | 26  GPIO 7 (SPI_CE1_N)
      ID_SD 27  | 28  ID_SC
    GPIO  5 29  | 30  GND
    GPIO  6 31  | 32  GPIO 12 (PWM0)
    GPIO 13 33  | 34  GND
    GPIO 19 35  | 36  GPIO 16 (CE2)
    GPIO 26 37  | 38  GPIO 20
        GND 39  | 40  GPIO 21
```

## How to Update Your Hardware

1. **Disconnect power** from your Raspberry Pi before making any connections.

2. **Update the software** by ensuring you're using the latest settings.py file with the new pin assignments.

3. **Reconnect your rotary encoder** to the new pins:
   - Connect CLK to GPIO 12 (Physical Pin 32)
   - Connect DT to GPIO 13 (Physical Pin 33)
   - Connect SW to GPIO 16 (Physical Pin 36)

4. **Reconnect your physical buttons** if you have them wired differently:
   - Top button to GPIO 5 (Physical Pin 29)
   - Middle button to GPIO 6 (Physical Pin 31)
   - Bottom button to GPIO 19 (Physical Pin 35)

5. **Reboot your Raspberry Pi** to ensure all changes take effect.

## Testing

After reconnecting everything:
1. Power on your Raspberry Pi
2. Check that the display works normally
3. Test that your rotary encoder functions properly
4. Verify that physical buttons work if connected
5. Test that camera triggering works if connected

## Troubleshooting

If you still experience issues:
- Double-check all connections match the new pin assignments
- Ensure no wires are loose or making poor contact
- Verify that your rotary encoder has built-in pull-up/pull-down resistors or add external ones
- Check that the GPIO pins are not damaged
- Review the system logs for any GPIO-related errors