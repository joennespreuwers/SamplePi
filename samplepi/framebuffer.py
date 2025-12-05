"""Direct framebuffer rendering for displays that don't work with SDL drivers"""

import os
import mmap
import struct


class Framebuffer:
    """Direct framebuffer access for ILI9486 and similar displays"""

    def __init__(self, device="/dev/fb0"):
        self.device = device
        self.fbfd = None
        self.fbmmap = None
        self.width = 0
        self.height = 0
        self.bpp = 0
        self.stride = 0

        try:
            self._open_framebuffer()
        except Exception as e:
            print(f"Warning: Could not open framebuffer {device}: {e}")
            print("Framebuffer output will not work")

    def _open_framebuffer(self):
        """Open and memory-map the framebuffer device"""
        # Open framebuffer
        self.fbfd = os.open(self.device, os.O_RDWR)

        # Get framebuffer info from sysfs
        fb_name = os.path.basename(self.device)

        # Read resolution
        with open(f"/sys/class/graphics/{fb_name}/virtual_size", 'r') as f:
            width, height = map(int, f.read().strip().split(','))
            self.width = width
            self.height = height

        # Read bits per pixel
        with open(f"/sys/class/graphics/{fb_name}/bits_per_pixel", 'r') as f:
            self.bpp = int(f.read().strip())

        # Calculate stride (bytes per line)
        self.stride = (self.width * self.bpp) // 8

        # Memory map the framebuffer
        fbsize = self.stride * self.height
        self.fbmmap = mmap.mmap(self.fbfd, fbsize, mmap.MAP_SHARED, mmap.PROT_READ | mmap.PROT_WRITE)

        print(f"Framebuffer opened: {self.width}x{self.height}, {self.bpp}bpp, stride={self.stride}")

    def blit(self, surface):
        """Blit a pygame surface to the framebuffer"""
        if not self.fbmmap:
            return

        # Convert pygame surface to RGB565 format (most common for small TFT displays)
        import pygame

        # Scale surface to framebuffer size if needed
        if surface.get_size() != (self.width, self.height):
            surface = pygame.transform.scale(surface, (self.width, self.height))

        # Convert to 16-bit RGB565 if framebuffer is 16bpp
        if self.bpp == 16:
            self._blit_rgb565(surface)
        elif self.bpp == 32:
            self._blit_rgb888(surface)
        else:
            print(f"Unsupported framebuffer depth: {self.bpp}bpp")

    def _blit_rgb565(self, surface):
        """Convert and blit surface as RGB565"""
        import pygame

        # Get pixel data
        pixels = pygame.surfarray.array3d(surface)

        # Convert to RGB565 format
        for y in range(self.height):
            for x in range(self.width):
                r, g, b = pixels[x, y]

                # Pack to RGB565: RRRRRGGGGGGBBBBB
                rgb565 = ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | ((b & 0xF8) >> 3)

                # Write to framebuffer
                offset = y * self.stride + x * 2
                self.fbmmap[offset:offset+2] = struct.pack('H', rgb565)

    def _blit_rgb888(self, surface):
        """Convert and blit surface as RGB888 (32bpp)"""
        import pygame

        # Get pixel data as string
        pixels = pygame.image.tostring(surface, 'RGBX')

        # Write directly to framebuffer
        self.fbmmap[:len(pixels)] = pixels

    def clear(self):
        """Clear the framebuffer to black"""
        if self.fbmmap:
            self.fbmmap[:] = b'\x00' * len(self.fbmmap)

    def close(self):
        """Close the framebuffer"""
        if self.fbmmap:
            self.fbmmap.close()
        if self.fbfd:
            os.close(self.fbfd)

    def is_available(self):
        """Check if framebuffer is available"""
        return self.fbmmap is not None
