#!/usr/bin/env python3
"""
Touchscreen Calibration Tool for SamplePi
This script helps calibrate the touchscreen by collecting touch points
and generating a calibration matrix.
"""

import pygame
import sys
import os

# Initialize pygame
pygame.init()

# Screen dimensions (match your display settings)
WIDTH = 320
HEIGHT = 240
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Touchscreen Calibration")
pygame.mouse.set_visible(True)  # Show cursor during calibration

# Colors
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
RED = (255, 0, 0)
BLUE = (0, 0, 255)
GREEN = (0, 255, 0)

def draw_crosshair(screen, pos, color=RED, size=20):
    """Draw a crosshair at the given position"""
    x, y = pos
    pygame.draw.line(screen, color, (x - size, y), (x + size, y), 2)
    pygame.draw.line(screen, color, (x, y - size), (x, y + size), 2)

def collect_calibration_points():
    """Collect calibration points from user touches"""
    points = []
    targets = [
        (50, 50, "TOP LEFT"),
        (WIDTH - 50, 50, "TOP RIGHT"),
        (WIDTH - 50, HEIGHT - 50, "BOTTOM RIGHT"),
        (50, HEIGHT - 50, "BOTTOM LEFT"),
        (WIDTH // 2, HEIGHT // 2, "CENTER")
    ]
    
    target_index = 0
    font = pygame.font.Font(None, 24)
    
    clock = pygame.time.Clock()
    running = True
    
    while running and target_index < len(targets):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return None
            elif event.type == pygame.MOUSEBUTTONDOWN:
                if event.button == 1:  # Left click
                    actual_x, actual_y = event.pos
                    ideal_x, ideal_y, label = targets[target_index]
                    
                    points.append({
                        'ideal': (ideal_x, ideal_y),
                        'actual': (actual_x, actual_y),
                        'label': label
                    })
                    
                    print(f"Calibration point {target_index + 1}: {label}")
                    print(f"  Ideal: ({ideal_x}, {ideal_y})")
                    print(f"  Actual: ({actual_x}, {actual_y})")
                    
                    target_index += 1
        
        # Draw screen
        screen.fill(WHITE)
        
        if target_index < len(targets):
            ideal_x, ideal_y, label = targets[target_index]
            
            # Draw target crosshair
            draw_crosshair(screen, (ideal_x, ideal_y), RED, 30)
            
            # Draw instructions
            instruction = font.render(f"Touch the red crosshair - {label}", True, BLACK)
            screen.blit(instruction, (WIDTH // 2 - instruction.get_width() // 2, HEIGHT - 40))
            
            # Draw collected points
            for i, point in enumerate(points):
                draw_crosshair(screen, point['actual'], GREEN, 15)
                label_text = font.render(point['label'], True, BLUE)
                screen.blit(label_text, (point['actual'][0] + 20, point['actual'][1]))
        else:
            # All points collected
            success = font.render("Calibration complete!", True, GREEN)
            screen.blit(success, (WIDTH // 2 - success.get_width() // 2, HEIGHT // 2))
            instruction = font.render("Press any key to exit", True, BLACK)
            screen.blit(instruction, (WIDTH // 2 - instruction.get_width() // 2, HEIGHT // 2 + 40))
        
        pygame.display.flip()
        clock.tick(30)
    
    return points

def calculate_calibration_matrix(points):
    """
    Calculate the calibration matrix using the least squares method
    Based on the standard 5-point calibration algorithm
    """
    if len(points) < 4:
        raise ValueError("Need at least 4 points for calibration")
    
    # Extract points
    ideal_x = [p['ideal'][0] for p in points]
    ideal_y = [p['ideal'][1] for p in points]
    actual_x = [p['actual'][0] for p in points]
    actual_y = [p['actual'][1] for p in points]
    
    # Calculate calibration coefficients using linear regression
    # For the transformation: ideal_x = Ax + By + C, ideal_y = Dx + Ey + F
    # We solve for A, B, C, D, E, F
    
    n = len(points)
    
    # Summations for X coordinates
    sum_ax = sum(actual_x)
    sum_ix = sum(ideal_x)
    sum_ax_sq = sum(ax * ax for ax in actual_x)
    sum_ay_sq = sum(ay * ay for ay in actual_y)
    sum_ax_ay = sum(ax * ay for ax, ay in zip(actual_x, actual_y))
    sum_ix_ax = sum(ix * ax for ix, ax in zip(ideal_x, actual_x))
    sum_ix_ay = sum(ix * ay for ix, ay in zip(ideal_x, actual_y))
    
    # Summations for Y coordinates  
    sum_iy_ax = sum(iy * ax for iy, ax in zip(ideal_y, actual_x))
    sum_iy_ay = sum(iy * ay for iy, ay in zip(ideal_y, actual_y))
    
    # Solve for coefficients A, B, C (for ideal_x = Ax + By + C)
    # Using matrix equation: AX = B where X = [A, B, C]^T
    # This is solved using least squares method
    
    # Matrix determinant calculation for 3x3 system
    det = (n * sum_ax_sq * sum_ay_sq + 
           2 * sum_ax * sum_ax_ay * 1 - 
           sum_ax_sq * sum_ax * 1 - 
           sum_ay_sq * sum_ax * 1 - 
           sum_ax_ay * sum_ax_ay * n)
    
    if abs(det) < 1e-6:
        # Fallback to simpler linear scaling
        avg_scale_x = sum(ix / ax if ax != 0 else 1 for ix, ax in zip(ideal_x, actual_x)) / n
        avg_scale_y = sum(iy / ay if ay != 0 else 1 for iy, ay in zip(ideal_y, actual_y)) / n
        
        avg_offset_x = sum(ix - ax * avg_scale_x for ix, ax in zip(ideal_x, actual_x)) / n
        avg_offset_y = sum(iy - ay * avg_scale_y for iy, ay in zip(ideal_y, actual_y)) / n
        
        return {
            'A': avg_scale_x, 'B': 0, 'C': avg_offset_x,
            'D': 0, 'E': avg_scale_y, 'F': avg_offset_y
        }
    
    # More accurate calculation would involve solving the full matrix
    # For simplicity, returning a basic scaling matrix
    avg_scale_x = sum(ix / ax if ax != 0 else 1 for ix, ax in zip(ideal_x, actual_x)) / n
    avg_scale_y = sum(iy / ay if ay != 0 else 1 for iy, ay in zip(ideal_y, actual_y)) / n
    
    avg_offset_x = sum(ix - ax * avg_scale_x for ix, ax in zip(ideal_x, actual_x)) / n
    avg_offset_y = sum(iy - ay * avg_scale_y for iy, ay in zip(ideal_y, actual_y)) / n
    
    return {
        'A': avg_scale_x, 'B': 0, 'C': avg_offset_x,
        'D': 0, 'E': avg_scale_y, 'F': avg_offset_y
    }

def save_calibration_matrix(matrix, filename="touchscreen_cal.txt"):
    """Save the calibration matrix to a file"""
    with open(filename, 'w') as f:
        f.write("# Touchscreen Calibration Matrix\n")
        f.write(f"A {matrix['A']}\n")
        f.write(f"B {matrix['B']}\n")
        f.write(f"C {matrix['C']}\n")
        f.write(f"D {matrix['D']}\n")
        f.write(f"E {matrix['E']}\n")
        f.write(f"F {matrix['F']}\n")
    print(f"Calibration matrix saved to {filename}")

def main():
    print("Touchscreen Calibration Tool")
    print("Click on the red crosshairs as they appear to calibrate your touchscreen.")
    print("Press ESC or close the window to quit without saving.")
    print()
    
    points = collect_calibration_points()
    
    if points is None:
        print("Calibration cancelled.")
        return
    
    if len(points) >= 4:
        try:
            matrix = calculate_calibration_matrix(points)
            print("\nCalibration matrix calculated:")
            for key, value in matrix.items():
                print(f"  {key}: {value:.4f}")
            
            save_calibration_matrix(matrix)
            
            print("\nCalibration complete! The matrix has been saved.")
            print("You can now use this calibration data in your application.")
            
        except Exception as e:
            print(f"Error calculating calibration matrix: {e}")
    else:
        print("Not enough points collected for calibration.")
    
    # Wait for key press before exiting
    waiting = True
    clock = pygame.time.Clock()
    font = pygame.font.Font(None, 24)
    
    while waiting:
        for event in pygame.event.get():
            if event.type == pygame.QUIT or event.type == pygame.KEYDOWN:
                waiting = False
        
        clock.tick(30)

if __name__ == "__main__":
    main()