"""Rotary encoder input handler"""

try:
    from gpiozero import RotaryEncoder as GPIORotaryEncoder, Button
    GPIO_AVAILABLE = True
except (ImportError, RuntimeError):
    GPIO_AVAILABLE = False
    print("Warning: GPIO not available. Running in mock mode.")

from samplepi.config import settings


class RotaryEncoder:
    """Handles rotary encoder input with button press"""

    def __init__(self):
        self.position = 0
        self.button_pressed = False
        self._on_rotate_callback = None
        self._on_press_callback = None
        self.encoder = None
        self.button = None

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

                # Initialize button
                self.button = Button(settings.ROTARY_SW_PIN, pull_up=True)
                self.button.when_pressed = self._handle_press
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

    def _handle_press(self):
        """Internal button press handler"""
        if self._on_press_callback:
            self._on_press_callback()

    def on_rotate(self, callback):
        """Register callback for rotation events"""
        self._on_rotate_callback = callback

    def on_press(self, callback):
        """Register callback for button press events"""
        self._on_press_callback = callback

    def simulate_rotation(self, direction):
        """Simulate rotation for testing (direction: 1 or -1)"""
        if self._on_rotate_callback:
            self._on_rotate_callback(direction)

    def simulate_press(self):
        """Simulate button press for testing"""
        if self._on_press_callback:
            self._on_press_callback()

    def cleanup(self):
        """Clean up GPIO resources"""
        if GPIO_AVAILABLE:
            if self.encoder:
                self.encoder.close()
            if self.button:
                self.button.close()
