#!/usr/bin/env python3
"""Main entry point for MediaPlayer application"""

import pygame
import sys
import os
import pathlib
import signal
import subprocess
from samplepi.config import settings
from samplepi.state import AppState
from samplepi.ui.screens import StartScreen
from samplepi.gpio import RotaryEncoder, CameraTrigger
from samplepi.gpio.touchscreen import TouchscreenButtons


def is_usb_gadget_mode():
    """Check if USB gadget mode is currently active"""
    gadget_path = "/sys/kernel/config/usb_gadget/samplepi/UDC"
    if os.path.exists(gadget_path):
        try:
            with open(gadget_path, 'r') as f:
                content = f.read().strip()
                return len(content) > 0
        except Exception:
            pass
    return False


class MediaPlayerApp:
    def __init__(self):
        """Initialize the MediaPlayer application"""
        pygame.init()

        # Run fullscreen pygame application
        print("Initializing fullscreen display")
        self.screen = pygame.display.set_mode(
            (settings.DISPLAY_WIDTH, settings.DISPLAY_HEIGHT),
            pygame.FULLSCREEN
        )
        pygame.mouse.set_visible(False)
        pygame.display.set_caption("SamplePi")
        print(f"Display initialized: {settings.DISPLAY_WIDTH}x{settings.DISPLAY_HEIGHT} fullscreen")

        self.clock = pygame.time.Clock()
        self.running = True

        # Load fonts
        self.font_large = pygame.font.Font(None, settings.FONT_SIZE_LARGE)
        self.font_medium = pygame.font.Font(None, settings.FONT_SIZE_MEDIUM)
        self.font_small = pygame.font.Font(None, settings.FONT_SIZE_SMALL)

        # Initialize state
        self.state = AppState()

        # Check if we're in USB gadget mode
        self.usb_gadget_mode = is_usb_gadget_mode()
        if self.usb_gadget_mode:
            print("USB Gadget Mode detected - starting in gadget mode UI")
        else:
            print("Normal mode - starting application")

        # Initialize audio player
        from samplepi.audio import AudioPlayer
        self.audio_player = AudioPlayer()

        # Initialize GPIO (with mock mode for desktop)
        self.rotary = RotaryEncoder()
        self.camera_trigger = CameraTrigger()
        self.touchscreen = TouchscreenButtons()

        # Set up rotary encoder callbacks (only in normal mode)
        if not self.usb_gadget_mode:
            self.rotary.on_rotate(self.handle_scroll)
            self.rotary.on_press(self.handle_select)
            self.rotary.on_long_press(self.handle_long_press)

        # Set up touchscreen button callbacks
        if not self.usb_gadget_mode:
            # Normal mode callbacks
            self.touchscreen.on_top(self.handle_top_button)
            self.touchscreen.on_middle(self.handle_middle_button)
            self.touchscreen.on_bottom(self.handle_bottom_button)
            self.touchscreen.on_top_long_press(self.handle_usb_gadget_toggle)
        else:
            # Gadget mode callbacks - only top button long press to exit
            self.touchscreen.on_top_long_press(self.handle_usb_gadget_toggle)

        # Start with appropriate screen
        if self.usb_gadget_mode:
            from samplepi.ui.screens.usb_gadget_mode_screen import UsbGadgetModeScreen
            self.state.goto_screen(UsbGadgetModeScreen(self))
        else:
            self.state.goto_screen(StartScreen(self))

    def handle_usb_gadget_toggle(self):
        """Handle long press on top button - toggle USB gadget mode"""
        print("USB Gadget toggle requested...")
        
        # Show a brief message before exiting
        if self.usb_gadget_mode:
            print("Exiting USB gadget mode...")
        else:
            print("Entering USB gadget mode...")
        
        # Call the toggle script
        try:
            home_dir = str(pathlib.Path.home())
            toggle_script = os.path.join(home_dir, "SamplePi/usb_gadget/toggle_gadget_button.sh")

            if not os.path.exists(toggle_script):
                # Fallback to system-wide installation
                toggle_script = "/usr/local/bin/samplepi_toggle_gadget.sh"

            if os.path.exists(toggle_script):
                subprocess.Popen(["sudo", toggle_script])
                # Shut down the app cleanly while the system prepares to reboot
                self.running = False
            else:
                print(f"Toggle script not found at {toggle_script}")
        except Exception as e:
            print(f"Error running toggle script: {e}")

    def handle_top_button(self):
        """Handle top button press - Home / Go to start screen"""
        if self.state.current_screen and hasattr(self.state.current_screen, 'handle_top_button'):
            self.state.current_screen.handle_top_button()
        else:
            # Go to start screen
            from samplepi.ui.screens import StartScreen
            self.state.goto_screen(StartScreen(self))

    def handle_middle_button(self):
        """Handle middle button press - Context action (Pause/Resume during playback)"""
        if self.state.current_screen and hasattr(self.state.current_screen, 'handle_middle_button'):
            self.state.current_screen.handle_middle_button()
        elif self.state.current_screen and hasattr(self.state.current_screen, 'handle_select'):
            # Default to select action
            self.state.current_screen.handle_select()

    def handle_bottom_button(self):
        """Handle bottom button press - Back / Stop"""
        if self.state.current_screen and hasattr(self.state.current_screen, 'handle_bottom_button'):
            self.state.current_screen.handle_bottom_button()
        elif self.state.current_screen and hasattr(self.state.current_screen, 'handle_long_press'):
            # Default to long press action (e.g., stop playback)
            self.state.current_screen.handle_long_press()

    def run(self):
        """Main application loop"""
        print("Starting main event loop...")
        frame_count = 0
        while self.running:
            self.handle_events()
            self.update()
            self.render()
            self.clock.tick(settings.FPS)

            # Print status every 60 frames (once per second at 60 FPS)
            frame_count += 1
            if frame_count % 60 == 0:
                print(f"App running... (frame {frame_count})")

        print("Exiting main loop, cleaning up...")
        self.cleanup()

    def handle_events(self):
        """Handle pygame events"""
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                print("Received QUIT event, shutting down...")
                self.running = False
            elif event.type == pygame.KEYDOWN:
                self.handle_keyboard(event.key)
            elif event.type == pygame.MOUSEBUTTONDOWN:
                self.handle_mouse(event.pos, event.button)

    def handle_keyboard(self, key):
        """Handle keyboard input (for testing on Mac)"""
        # NOTE: ESC key is only for development testing
        # Remove or disable this in production on Raspberry Pi
        if key == pygame.K_ESCAPE:
            self.running = False
        elif key == pygame.K_UP:
            self.handle_scroll(-1)
        elif key == pygame.K_DOWN:
            self.handle_scroll(1)
        elif key == pygame.K_RETURN or key == pygame.K_SPACE:
            self.handle_select()
        elif key == pygame.K_l:  # L = Long press
            self.handle_long_press()
        elif key == pygame.K_t:  # T = Toggle USB gadget (for testing)
            self.handle_usb_gadget_toggle()
        elif key == pygame.K_h:  # H = Home
            self.handle_top_button()
        elif key == pygame.K_m:  # M = Middle button
            self.handle_middle_button()
        elif key == pygame.K_b:  # B = Bottom button
            self.handle_bottom_button()

    def handle_mouse(self, pos, button):
        """Handle mouse/touch input"""
        # Get current screen and check if it has mouse handling capabilities
        if self.state.current_screen and hasattr(self.state.current_screen, 'handle_input'):
            # Pass the mouse event to the current screen
            self.state.current_screen.handle_input(pos, button)

    def handle_scroll(self, direction):
        """Handle scroll input"""
        if self.state.current_screen:
            self.state.current_screen.handle_scroll(direction)

    def handle_select(self):
        """Handle select/enter input"""
        if self.state.current_screen:
            self.state.current_screen.handle_select()

    def handle_long_press(self):
        """Handle long press input"""
        if self.state.current_screen and hasattr(self.state.current_screen, 'handle_long_press'):
            self.state.current_screen.handle_long_press()

    def update(self):
        """Update application state"""
        if self.state.current_screen:
            self.state.current_screen.update()

    def render(self):
        """Render the current screen"""
        if self.state.current_screen:
            self.state.current_screen.render()

        pygame.display.flip()

    def cleanup(self):
        """Clean up resources"""
        self.rotary.cleanup()
        self.camera_trigger.cleanup()
        self.touchscreen.cleanup()
        pygame.quit()
        sys.exit(0)


def main():
    """Entry point"""
    app = MediaPlayerApp()

    # Handle termination signals gracefully
    def signal_handler(signum, frame):
        print(f"Received signal {signum}, shutting down gracefully...")
        app.running = False

    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    app.run()


if __name__ == "__main__":
    main()
