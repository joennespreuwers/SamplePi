"""Scrollable menu list component"""

import pygame
from samplepi.config import settings


class MenuList:
    """Scrollable list of menu items with selection"""

    def __init__(self, items, y_start=80, item_height=40):
        self.items = items
        self.selected_index = 0
        self.y_start = y_start
        self.item_height = item_height
        self.visible_items = 5

    def scroll(self, direction):
        """Scroll selection (1 = down, -1 = up)"""
        self.selected_index += direction
        self.selected_index = max(0, min(len(self.items) - 1, self.selected_index))

    def get_selected(self):
        """Get currently selected item"""
        if 0 <= self.selected_index < len(self.items):
            return self.items[self.selected_index]
        return None

    def get_selected_index(self):
        """Get selected index"""
        return self.selected_index

    def render(self, screen, font):
        """Render the menu list"""
        # Calculate visible range
        start_idx = max(0, self.selected_index - self.visible_items // 2)
        end_idx = min(len(self.items), start_idx + self.visible_items)

        # Adjust if at end of list
        if end_idx - start_idx < self.visible_items:
            start_idx = max(0, end_idx - self.visible_items)

        # Draw items
        y = self.y_start
        for i in range(start_idx, end_idx):
            item = self.items[i]
            is_selected = (i == self.selected_index)

            # Draw selection background
            if is_selected:
                rect = pygame.Rect(40, y - 5, settings.DISPLAY_WIDTH - 80, self.item_height)
                pygame.draw.rect(screen, settings.COLOR_BUTTON_ACTIVE, rect)
                pygame.draw.rect(screen, settings.COLOR_HIGHLIGHT, rect, 2)

            # Draw item text
            color = settings.COLOR_HIGHLIGHT if is_selected else settings.COLOR_TEXT
            text = font.render(str(item), True, color)
            text_rect = text.get_rect(left=60, centery=y + self.item_height // 2 - 5)
            screen.blit(text, text_rect)

            y += self.item_height

        # Draw scroll indicator if needed
        if len(self.items) > self.visible_items:
            indicator_text = f"{self.selected_index + 1}/{len(self.items)}"
            indicator = font.render(indicator_text, True, settings.COLOR_TEXT)
            indicator_rect = indicator.get_rect(right=settings.DISPLAY_WIDTH - 20, top=self.y_start)
            screen.blit(indicator, indicator_rect)
