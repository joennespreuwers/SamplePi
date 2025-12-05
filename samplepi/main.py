#!/usr/bin/env python3
"""Main entry point for MediaPlayer application"""

import pygame
import sys
import os
import signal
from samplepi.config import settings
from samplepi.state import AppState
from samplepi.ui.screens import StartScreen
from samplepi.gpio import RotaryEncoder, CameraTrigger
from samplepi.gpio.touchscreen import TouchscreenButtons


class MediaPlayerApp:
    def __init__(self):
        """Initialize the MediaPlayer application"""
        pygame.init()

        # Check if we're running in a desktop environment
        has_display = 'DISPLAY' in os.environ or os.environ.get('WAYLAND_DISPLAY')

        if has_display:
            # Desktop mode - use X11/Wayland with fullscreen
            print("Running in desktop mode with fullscreen display")
            self.screen = pygame.display.set_mode(
                (settings.DISPLAY_WIDTH, settings.DISPLAY_HEIGHT),
                pygame.FULLSCREEN | pygame.HWSURFACE | pygame.DOUBLEBUF
            )
            pygame.mouse.set_visible(False)  # Hide mouse cursor in fullscreen
            pygame.display.set_caption("SamplePi")
            print(f"Display initialized: {settings.DISPLAY_WIDTH}x{settings.DISPLAY_HEIGHT} fullscreen")
            self.framebuffer = None
        else:
            # Headless/framebuffer mode - try various drivers
            print("Running in headless mode, trying framebuffer drivers...")
            drivers_to_try = []

            # Check if SDL environment variables are set (from systemd service)
            if 'SDL_VIDEODRIVER' in os.environ:
                drivers_to_try.append(os.environ['SDL_VIDEODRIVER'])

            # Add fallback drivers
            drivers_to_try.extend(['kmsdrm', 'fbcon', 'directfb', 'dummy'])

            # Try to initialize display with each driver
            self.screen = None
            for driver in drivers_to_try:
                try:
                    print(f"Trying SDL video driver: {driver}")
                    os.environ['SDL_VIDEODRIVER'] = driver
                    if driver in ['fbcon', 'directfb', 'kmsdrm']:
                        os.environ['SDL_FBDEV'] = '/dev/fb0'
                        os.environ['SDL_NOMOUSE'] = '1'

                    self.screen = pygame.display.set_mode(
                        (settings.DISPLAY_WIDTH, settings.DISPLAY_HEIGHT)
                    )
                    pygame.display.set_caption("SamplePi")
                    print(f"Successfully initialized display with {driver} driver")
                    break
                except pygame.error as e:
                    print(f"Failed to initialize with {driver}: {e}")
                    if driver != drivers_to_try[-1]:
                        pygame.display.quit()
                    continue

            if not self.screen:
                print("ERROR: Could not initialize display with any driver")
                sys.exit(1)

            # Try direct framebuffer rendering if using dummy driver
            self.framebuffer = None
            if os.environ.get('SDL_VIDEODRIVER') == 'dummy' and os.path.exists('/dev/fb0'):
                print("Attempting direct framebuffer rendering...")
                from samplepi.framebuffer import Framebuffer
                self.framebuffer = Framebuffer('/dev/fb0')
                if self.framebuffer.is_available():
                    print("Direct framebuffer rendering enabled")
                else:
                    print("Direct framebuffer rendering unavailable")

        self.clock = pygame.time.Clock()
        self.running = True

        # Load fonts
        self.font_large = pygame.font.Font(None, settings.FONT_SIZE_LARGE)
        self.font_medium = pygame.font.Font(None, settings.FONT_SIZE_MEDIUM)
        self.font_small = pygame.font.Font(None, settings.FONT_SIZE_SMALL)

        # Initialize state
        self.state = AppState()

        # Initialize audio player
        from samplepi.audio import AudioPlayer
        self.audio_player = AudioPlayer()

        # Initialize GPIO (with mock mode for desktop)
        self.rotary = RotaryEncoder()
        self.camera_trigger = CameraTrigger()
        self.touchscreen = TouchscreenButtons()

        # Set up rotary encoder callbacks
        self.rotary.on_rotate(self.handle_scroll)
        self.rotary.on_press(self.handle_select)

        # Set up touchscreen callbacks
        # Top button = Home (left), Middle button = Next (right), Bottom button = Back (middle)
        self.touchscreen.on_left(lambda: self.handle_button("left"))
        self.touchscreen.on_middle(lambda: self.handle_button("right"))
        self.touchscreen.on_right(lambda: self.handle_button("middle"))

        # Start with home screen
        self.state.goto_screen(StartScreen(self))

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
        elif key == pygame.K_h:  # H = Home button (top button)
            self.handle_button("left")
        elif key == pygame.K_n:  # N = Next button (middle button)
            self.handle_button("right")
        elif key == pygame.K_b:  # B = Back button (bottom button)
            self.handle_button("middle")

    def handle_scroll(self, direction):
        """Handle scroll input"""
        if self.state.current_screen:
            self.state.current_screen.handle_scroll(direction)

    def handle_select(self):
        """Handle select/enter input"""
        if self.state.current_screen:
            self.state.current_screen.handle_select()

    def handle_button(self, button):
        """Handle button press"""
        if self.state.current_screen:
            self.state.current_screen.handle_button(button)

    def update(self):
        """Update application state"""
        if self.state.current_screen:
            self.state.current_screen.update()

    def render(self):
        """Render the current screen"""
        if self.state.current_screen:
            self.state.current_screen.render()

        pygame.display.flip()

        # Also blit to framebuffer if available
        if self.framebuffer and self.framebuffer.is_available():
            self.framebuffer.blit(self.screen)

    def cleanup(self):
        """Clean up resources"""
        self.rotary.cleanup()
        self.camera_trigger.cleanup()
        if self.framebuffer:
            self.framebuffer.close()
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
