"""Rotary encoder input handler"""

import time
import threading

try:
    from gpiozero import RotaryEncoder as GPIORotaryEncoder, Button
    GPIO_AVAILABLE = True
except (ImportError, RuntimeError):
    GPIO_AVAILABLE = False
    print("Warning: GPIO not available. Running in mock mode.")

from samplepi.config import settings


class RotaryEncoder:
    """Handles rotary encoder input with button press and long press detection"""

    def __init__(self, long_press_duration=0.5):
        self.position = 0
        self.button_pressed = False
        self._on_rotate_callback = None
        self._on_press_callback = None
        self._on_long_press_callback = None
        self.encoder = None
        self.button = None

        # Long press detection
        self.long_press_duration = long_press_duration
        self._press_start_time = None
        self._long_press_triggered = False
        self._press_timer = None

        if GPIO_AVAILABLE:
            try:
                # Initialize rotary encoder
                self.encoder = GPIORotaryEncoder(
                    settings.ROTARY_CLK_PIN,
                    settings.ROTARY_DT_PIN,
                    wrap=False,
                    max_steps=1000
                )
                self.encoder.when_rotated = self._handle_rotation

                # Initialize button with press and release handlers
                self.button = Button(settings.ROTARY_SW_PIN, pull_up=True)
                self.button.when_pressed = self._handle_button_down
                self.button.when_released = self._handle_button_up
            except (RuntimeError, Exception) as e:
                print(f"Warning: Could not initialize rotary encoder: {e}")
                print("Running in mock GPIO mode")
                self.encoder = None
                self.button = None

    def _handle_rotation(self):
        """Internal rotation handler"""
        if self.encoder:
            steps = self.encoder.steps
            direction = 1 if steps > self.position else -1
            self.position = steps

            if self._on_rotate_callback:
                self._on_rotate_callback(direction)

    def _handle_button_down(self):
        """Internal button press down handler"""
        self._press_start_time = time.time()
        self._long_press_triggered = False

        # Start timer for long press detection
        if self._press_timer:
            self._press_timer.cancel()
        self._press_timer = threading.Timer(self.long_press_duration, self._trigger_long_press)
        self._press_timer.start()

    def _handle_button_up(self):
        """Internal button release handler"""
        # Cancel long press timer
        if self._press_timer:
            self._press_timer.cancel()
            self._press_timer = None

        # If long press wasn't triggered, treat as short press
        if not self._long_press_triggered and self._on_press_callback:
            self._on_press_callback()

        self._press_start_time = None
        self._long_press_triggered = False

    def _trigger_long_press(self):
        """Trigger long press callback"""
        self._long_press_triggered = True
        if self._on_long_press_callback:
            self._on_long_press_callback()

    def on_rotate(self, callback):
        """Register callback for rotation events"""
        self._on_rotate_callback = callback

    def on_press(self, callback):
        """Register callback for short button press events"""
        self._on_press_callback = callback

    def on_long_press(self, callback):
        """Register callback for long button press events"""
        self._on_long_press_callback = callback

    def simulate_rotation(self, direction):
        """Simulate rotation for testing (direction: 1 or -1)"""
        if self._on_rotate_callback:
            self._on_rotate_callback(direction)

    def simulate_press(self):
        """Simulate short button press for testing"""
        if self._on_press_callback:
            self._on_press_callback()

    def simulate_long_press(self):
        """Simulate long button press for testing"""
        if self._on_long_press_callback:
            self._on_long_press_callback()

    def cleanup(self):
        """Clean up GPIO resources"""
        # Cancel any pending timers
        if self._press_timer:
            self._press_timer.cancel()
            self._press_timer = None

        if GPIO_AVAILABLE:
            if self.encoder:
                self.encoder.close()
            if self.button:
                self.button.close()
