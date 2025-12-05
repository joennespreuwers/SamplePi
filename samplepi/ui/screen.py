"""Base Screen class for all menu screens"""

import pygame
from samplepi.config import settings


class Screen:
    """Base class for all screens in the application"""

    def __init__(self, app):
        self.app = app
        self.screen = app.screen
        self.font_large = app.font_large
        self.font_medium = app.font_medium
        self.font_small = app.font_small

    def handle_input(self, event):
        """Handle input events (keyboard, mouse, etc.)"""
        pass

    def handle_button(self, button):
        """Handle button press (left/middle/right)"""
        pass

    def handle_scroll(self, direction):
        """Handle scroll input (1 = down, -1 = up)"""
        pass

    def handle_select(self):
        """Handle select/enter input"""
        pass

    def update(self):
        """Update screen state"""
        pass

    def render(self):
        """Render the screen"""
        pass

    def draw_title(self, text, y=30):
        """Draw centered title text"""
        title = self.font_large.render(text, True, settings.COLOR_TEXT)
        title_rect = title.get_rect(center=(settings.DISPLAY_WIDTH // 2, y))
        self.screen.blit(title, title_rect)

    def draw_text(self, text, y, font=None, color=None):
        """Draw centered text"""
        if font is None:
            font = self.font_medium
        if color is None:
            color = settings.COLOR_TEXT

        text_surface = font.render(text, True, color)
        text_rect = text_surface.get_rect(center=(settings.DISPLAY_WIDTH // 2, y))
        self.screen.blit(text_surface, text_rect)

    def draw_buttons(self, labels):
        """Draw three bottom buttons with labels"""
        button_width = settings.DISPLAY_WIDTH // 3
        button_y = settings.DISPLAY_HEIGHT - settings.BUTTON_HEIGHT

        for i, label in enumerate(labels):
            if label is None:
                continue

            x = i * button_width

            # Draw button background
            button_rect = pygame.Rect(x, button_y, button_width, settings.BUTTON_HEIGHT)
            pygame.draw.rect(self.screen, settings.COLOR_BUTTON, button_rect)
            pygame.draw.rect(self.screen, settings.COLOR_TEXT, button_rect, 2)

            # Draw button label
            text = self.font_medium.render(label, True, settings.COLOR_TEXT)
            text_rect = text.get_rect(center=(x + button_width // 2, button_y + settings.BUTTON_HEIGHT // 2))
            self.screen.blit(text, text_rect)
