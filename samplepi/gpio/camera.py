"""Camera trigger GPIO output handler"""

import time
try:
    from gpiozero import OutputDevice
    GPIO_AVAILABLE = True
except (ImportError, RuntimeError):
    GPIO_AVAILABLE = False
    print("Warning: GPIO not available. Running in mock mode.")

from samplepi.config import settings


class CameraTrigger:
    """Handles camera trigger GPIO output"""

    def __init__(self):
        self.trigger = None
        if GPIO_AVAILABLE:
            try:
                self.trigger = OutputDevice(
                    settings.CAMERA_TRIGGER_PIN,
                    initial_value=False
                )
            except (RuntimeError, Exception) as e:
                print(f"Warning: Could not initialize camera trigger: {e}")
                print("Running in mock GPIO mode")
                self.trigger = None

    def send_pulse(self):
        """Send a 100ms HIGH pulse to trigger camera recording"""
        if self.trigger:
            self.trigger.on()
            time.sleep(settings.CAMERA_TRIGGER_DURATION)
            self.trigger.off()
            print("Camera trigger: pulse sent")
        else:
            print("Camera trigger: pulse sent (mock mode)")

    def cleanup(self):
        """Clean up GPIO resources"""
        if GPIO_AVAILABLE and self.trigger:
            self.trigger.close()
