# Rotary Encoder Keyboard - Wiring Guide

## Pin Connections

Connect your rotary encoder to the Raspberry Pi Pico as follows:

### Rotary Encoder Pins:
- **CLK (or A)** → GPIO 2 (Pin 4 on Pico)
- **DT (or B)** → GPIO 3 (Pin 5 on Pico)
- **SW (Button)** → GPIO 4 (Pin 6 on Pico)
- **+ (VCC)** → 3V3 (OUT) (Pin 36 on Pico)
- **GND** → GND (any GND pin, e.g., Pin 3, 8, 13, 18, 23, 28, 33, or 38)

## Functionality

Once connected, the Pico will act as a USB keyboard:

- **Right Rotation (Clockwise)** → Arrow Down ↓
- **Left Rotation (Counter-clockwise)** → Arrow Up ↑
- **Short Button Press** → Enter ⏎
- **Long Button Press (500ms+)** → L key

## Pico Pin Reference

```
     USB Port
        ||
    +-------+
    |  1  2 |
    |  3  4 | ← GPIO 2 (CLK)
    |  5  6 | ← GPIO 3 (DT) / GPIO 4 (SW)
    |  7  8 |
    | ... . |
    +-------+
```

## Troubleshooting

1. **Encoder not responding**: Check that CLK and DT are connected correctly
2. **Inverted direction**: Swap CLK and DT pins
3. **Button not working**: Verify SW pin connection
4. **No keyboard detected**: Reconnect USB cable to restart Pico

## Notes

- The encoder uses internal pull-up resistors (no external resistors needed)
- Debouncing is implemented in software
- Long press threshold is 500 milliseconds
