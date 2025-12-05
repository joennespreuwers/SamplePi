#!/usr/bin/env python3
"""Main entry point for MediaPlayer application"""

import pygame
import sys
import os
from samplepi.config import settings
from samplepi.state import AppState
from samplepi.ui.screens import StartScreen
from samplepi.gpio import RotaryEncoder, CameraTrigger
from samplepi.gpio.touchscreen import TouchscreenButtons


class MediaPlayerApp:
    def __init__(self):
        """Initialize the MediaPlayer application"""
        # Try different SDL video drivers in order of preference
        drivers_to_try = []

        # Check if SDL environment variables are set (from systemd service)
        if 'SDL_VIDEODRIVER' in os.environ:
            drivers_to_try.append(os.environ['SDL_VIDEODRIVER'])

        # Add fallback drivers
        drivers_to_try.extend(['fbcon', 'directfb', 'dummy'])

        # Try to initialize display with each driver
        self.screen = None
        for driver in drivers_to_try:
            try:
                print(f"Trying SDL video driver: {driver}")
                os.environ['SDL_VIDEODRIVER'] = driver
                if driver in ['fbcon', 'directfb']:
                    os.environ['SDL_FBDEV'] = '/dev/fb0'
                    os.environ['SDL_NOMOUSE'] = '1'

                pygame.init()
                self.screen = pygame.display.set_mode(
                    (settings.DISPLAY_WIDTH, settings.DISPLAY_HEIGHT)
                )
                pygame.display.set_caption("SamplePi")
                print(f"Successfully initialized display with {driver} driver")
                break
            except pygame.error as e:
                print(f"Failed to initialize with {driver}: {e}")
                if driver != drivers_to_try[-1]:  # If not the last driver
                    pygame.display.quit()
                    pygame.quit()
                continue

        if not self.screen:
            print("ERROR: Could not initialize display with any driver")
            sys.exit(1)

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
        while self.running:
            self.handle_events()
            self.update()
            self.render()
            self.clock.tick(settings.FPS)

        self.cleanup()

    def handle_events(self):
        """Handle pygame events"""
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
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

    def cleanup(self):
        """Clean up resources"""
        self.rotary.cleanup()
        self.camera_trigger.cleanup()
        pygame.quit()
        sys.exit(0)


def main():
    """Entry point"""
    app = MediaPlayerApp()
    app.run()


if __name__ == "__main__":
    main()
