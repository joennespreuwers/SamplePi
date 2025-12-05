"""File selection screen for WAV files"""

import os
import pygame
from samplepi.ui.screen import Screen
from samplepi.ui.menu_list import MenuList
from samplepi.config import settings


class FileSelectionScreen(Screen):
    """Screen for selecting multiple files"""

    def __init__(self, app, file_type, title):
        super().__init__(app)
        self.file_type = file_type  # 'test_wavs' or 'samples'
        self.title = title
        self.selected_files = set()

        # Get list of files
        self.files = self.get_files()
        if not self.files:
            self.files = ["No files found"]

        self.menu = MenuList(self.files, y_start=100, item_height=35)
        self.menu.visible_items = 4  # Show only 4 items to fit in box

    def get_files(self):
        """Get list of WAV files from directory"""
        if self.file_type == "test_wavs":
            directory = settings.TEST_WAVS_DIR
        else:
            directory = settings.SAMPLES_DIR

        # For testing on Mac, use dummy files if directory doesn't exist
        if not os.path.exists(directory):
            return [f"test_file_{i}.wav" for i in range(1, 8)]

        files = []
        for f in os.listdir(directory):
            if f.endswith('.wav'):
                files.append(f)
        return sorted(files) if files else []

    def handle_scroll(self, direction):
        """Handle scroll input"""
        self.menu.scroll(direction)

    def handle_select(self):
        """Handle select input - toggle file selection"""
        selected = self.menu.get_selected()
        if selected and selected != "No files found":
            if selected in self.selected_files:
                self.selected_files.remove(selected)
            else:
                self.selected_files.add(selected)

    def handle_button(self, button):
        """Handle button press"""
        if button == "left":  # Home
            from .start_screen import StartScreen
            self.app.state.go_home()
            self.app.state.goto_screen(StartScreen(self.app))
        elif button == "middle":  # Back
            self.app.state.go_back()
        elif button == "right":  # Next
            if self.selected_files:
                self.proceed_to_next()
            # If no files selected, do nothing

    def proceed_to_next(self):
        """Move to next screen based on file type"""
        if self.file_type == "test_wavs":
            # Save selections and go to samples selection
            self.app.state.selected_test_wavs = list(self.selected_files)
            self.app.state.goto_screen(
                FileSelectionScreen(self.app, "samples", "Select Sample Files")
            )
        else:
            # Save selections and go to recording toggle
            self.app.state.selected_samples = list(self.selected_files)
            from .recording_toggle_screen import RecordingToggleScreen
            self.app.state.goto_screen(RecordingToggleScreen(self.app))

    def render(self):
        """Render the screen"""
        self.screen.fill(settings.COLOR_BACKGROUND)
        self.draw_title(self.title)

        # Show selection count
        count_text = f"Selected: {len(self.selected_files)}"
        self.draw_text(count_text, 60, color=settings.COLOR_HIGHLIGHT)

        # Draw file browser box
        self.browser_rect = pygame.Rect(30, 90, settings.DISPLAY_WIDTH - 60, 160)
        pygame.draw.rect(self.screen, (40, 40, 50), self.browser_rect)
        pygame.draw.rect(self.screen, settings.COLOR_TEXT, self.browser_rect, 2)

        # Set clipping area to browser box (excluding scrollbar area)
        clip_rect = pygame.Rect(30, 90, settings.DISPLAY_WIDTH - 90, 160)
        self.screen.set_clip(clip_rect)

        # Render menu with checkmarks for selected items
        self.render_file_list()

        # Remove clipping
        self.screen.set_clip(None)

        # Draw scrollbar outside clip area
        if len(self.menu.items) > self.menu.visible_items:
            start_idx = max(0, self.menu.selected_index - self.menu.visible_items // 2)
            end_idx = min(len(self.menu.items), start_idx + self.menu.visible_items)
            self.draw_scrollbar(start_idx, end_idx)

        self.draw_buttons(["Home", "Back", "Next"])

    def render_file_list(self):
        """Render file list with selection indicators"""
        # Calculate visible range
        start_idx = max(0, self.menu.selected_index - self.menu.visible_items // 2)
        end_idx = min(len(self.menu.items), start_idx + self.menu.visible_items)

        if end_idx - start_idx < self.menu.visible_items:
            start_idx = max(0, end_idx - self.menu.visible_items)

        # Draw items
        y = self.menu.y_start
        for i in range(start_idx, end_idx):
            item = self.menu.items[i]
            is_selected = (i == self.menu.selected_index)
            is_checked = item in self.selected_files

            # Draw selection background
            if is_selected:
                rect = pygame.Rect(40, y - 5, settings.DISPLAY_WIDTH - 90, self.menu.item_height)
                pygame.draw.rect(self.screen, settings.COLOR_BUTTON_ACTIVE, rect)
                pygame.draw.rect(self.screen, settings.COLOR_HIGHLIGHT, rect, 2)

            # Draw checkbox
            checkbox_rect = pygame.Rect(50, y, 20, 20)
            pygame.draw.rect(self.screen, settings.COLOR_TEXT, checkbox_rect, 2)
            if is_checked:
                # Draw checkmark
                pygame.draw.line(self.screen, settings.COLOR_HIGHLIGHT,
                               (52, y + 10), (58, y + 16), 3)
                pygame.draw.line(self.screen, settings.COLOR_HIGHLIGHT,
                               (58, y + 16), (68, y + 6), 3)

            # Draw item text
            color = settings.COLOR_HIGHLIGHT if is_selected else settings.COLOR_TEXT
            text = self.font_small.render(str(item), True, color)
            text_rect = text.get_rect(left=80, centery=y + 10)
            self.screen.blit(text, text_rect)

            y += self.menu.item_height

    def draw_scrollbar(self, start_idx, end_idx):
        """Draw a visual scrollbar"""
        # Scrollbar position
        scrollbar_x = settings.DISPLAY_WIDTH - 50
        scrollbar_y = self.menu.y_start
        scrollbar_height = self.menu.visible_items * self.menu.item_height

        # Draw scrollbar track
        track_rect = pygame.Rect(scrollbar_x, scrollbar_y, 10, scrollbar_height)
        pygame.draw.rect(self.screen, (60, 60, 70), track_rect)
        pygame.draw.rect(self.screen, settings.COLOR_TEXT, track_rect, 1)

        # Calculate thumb size and position
        total_items = len(self.menu.items)
        thumb_height = max(20, scrollbar_height * self.menu.visible_items // total_items)
        thumb_y = scrollbar_y + (scrollbar_height - thumb_height) * self.menu.selected_index // (total_items - 1)

        # Draw scrollbar thumb
        thumb_rect = pygame.Rect(scrollbar_x, thumb_y, 10, thumb_height)
        pygame.draw.rect(self.screen, settings.COLOR_HIGHLIGHT, thumb_rect)
        pygame.draw.rect(self.screen, settings.COLOR_TEXT, thumb_rect, 1)

        # Draw page indicator text
        indicator_text = f"{self.menu.selected_index + 1}/{total_items}"
        indicator = self.font_small.render(indicator_text, True, settings.COLOR_TEXT)
        indicator_rect = indicator.get_rect(center=(scrollbar_x + 5, scrollbar_y - 15))
        self.screen.blit(indicator, indicator_rect)
