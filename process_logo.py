from PIL import Image, ImageDraw
import sys

input_path = r'C:\Users\DIWANs\.gemini\antigravity-ide\brain\8e8c6e1d-2e81-4686-b815-f8c74718a139\media__1782794426233.jpg'
output_path = r'd:\protega_organized\assets\app_icon_transparent.png'

img = Image.open(input_path).convert('RGBA')
width, height = img.size
data = img.getdata()

min_x = width
min_y = height
max_x = 0
max_y = 0

# Find bounding box
for y in range(height):
    for x in range(width):
        r, g, b, a = data[y * width + x]
        # Darker than the light gray background
        if r < 180 and g < 180 and b < 180:
            if x < min_x: min_x = x
            if x > max_x: max_x = x
            if y < min_y: min_y = y
            if y > max_y: max_y = y

print(f"Bounding box: {min_x}, {min_y}, {max_x}, {max_y}")

# Crop image
cropped = img.crop((min_x, min_y, max_x, max_y))
c_width, c_height = cropped.size

# To remove the corners, let's just make any pixel that is "light" in the cropped area transparent.
# But wait, the inner shield also has white color! We can't just make all white pixels transparent.
# Instead, we can apply a rounded rectangle mask if it's a rounded square icon, or we can just floodfill from the corners!
# Floodfill is much safer. Let's do a floodfill from the 4 corners.
ImageDraw.floodfill(cropped, xy=(0, 0), value=(0, 0, 0, 0), thresh=40)
ImageDraw.floodfill(cropped, xy=(c_width-1, 0), value=(0, 0, 0, 0), thresh=40)
ImageDraw.floodfill(cropped, xy=(0, c_height-1), value=(0, 0, 0, 0), thresh=40)
ImageDraw.floodfill(cropped, xy=(c_width-1, c_height-1), value=(0, 0, 0, 0), thresh=40)

import os
os.makedirs(os.path.dirname(output_path), exist_ok=True)
cropped.save(output_path)
print(f"Saved to {output_path}")
