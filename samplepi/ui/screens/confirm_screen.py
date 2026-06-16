"""Confirmation screen before starting playback"""

import pygame
from samplepi.ui.screen import Screen
from samplepi.config import settings


class ConfirmScreen(Screen):
    """Screen showing summary and ready to start"""

    def __init__(self, app):
        super().__init__(app)

    def handle_select(self):
        """Handle select input - start playback"""
        self.start_playback()

    def handle_long_press(self):
        """Handle long press - start playback"""
        self.start_playback()

    def start_playback(self):
        """Start playback and go to playback screen"""
        from .playback_screen import PlaybackScreen
        self.app.state.goto_screen(PlaybackScreen(self.app))

    def render(self):
        """Render the screen"""
        self.screen.fill(settings.COLOR_BACKGROUND)
        self.draw_title("Ready to Start")

        # Draw summary box (taller without buttons)
        box_rect = pygame.Rect(20, 70, settings.DISPLAY_WIDTH - 40, settings.DISPLAY_HEIGHT - 80)
        pygame.draw.rect(self.screen, (40, 40, 50), box_rect)
        pygame.draw.rect(self.screen, settings.COLOR_TEXT, box_rect, 2)

        y = 90

        # Total counts - more prominent
        total_files = len(self.app.state.selected_test_wavs) + len(self.app.state.selected_samples)
        self.draw_text(f"Total Files: {total_files}", y, self.font_medium, settings.COLOR_HIGHLIGHT)

        y += 40
        # Test WAVs count
        wavs_text = f"Test WAVs: {len(self.app.state.selected_test_wavs)}"
        text_surface = self.font_small.render(wavs_text, True, settings.COLOR_TEXT)
        text_rect = text_surface.get_rect(left=40, centery=y)
        self.screen.blit(text_surface, text_rect)

        y += 30
        # Samples count
        samples_text = f"Samples: {len(self.app.state.selected_samples)}"
        text_surface = self.font_small.render(samples_text, True, settings.COLOR_TEXT)
        text_rect = text_surface.get_rect(left=40, centery=y)
        self.screen.blit(text_surface, text_rect)

        y += 40
        # Recording status with icon
        rec_status = "ON" if self.app.state.record_video else "OFF"
        rec_color = settings.COLOR_HIGHLIGHT if self.app.state.record_video else (120, 120, 130)

        # Draw record indicator
        if self.app.state.record_video:
            pygame.draw.circle(self.screen, rec_color, (50, y), 8)
        else:
            pygame.draw.circle(self.screen, rec_color, (50, y), 8, 2)

        rec_text = f"Video Recording: {rec_status}"
        text_surface = self.font_small.render(rec_text, True, rec_color)
        text_rect = text_surface.get_rect(left=70, centery=y)
        self.screen.blit(text_surface, text_rect)
