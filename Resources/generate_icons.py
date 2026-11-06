#!/usr/bin/env python3
import os
import shutil
import subprocess
from PIL import Image, ImageDraw

def create_icon(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Margin & corner radius for macOS squircle
    margin = int(size * 0.08)
    rect = [margin, margin, size - margin, size - margin]
    radius = int(size * 0.22)
    
    # Outer squircle gradient background
    bg_color = (24, 26, 32, 255)
    border_color = (60, 64, 78, 255)
    
    draw.rounded_rectangle(rect, radius=radius, fill=bg_color, outline=border_color, width=max(1, int(size * 0.02)))
    
    # Window header traffic light dots
    dot_radius = max(2, int(size * 0.028))
    dot_y = margin + int(size * 0.09)
    dot_spacing = int(size * 0.075)
    start_x = margin + int(size * 0.09)
    
    colors = [(255, 95, 86, 255), (255, 189, 46, 255), (39, 201, 63, 255)]
    for i, col in enumerate(colors):
        cx = start_x + i * dot_spacing
        draw.ellipse([cx - dot_radius, dot_y - dot_radius, cx + dot_radius, dot_y + dot_radius], fill=col)
        
    # Draw terminal prompt `>` and `_`
    stroke_w = max(2, int(size * 0.048))
    
    # Chevron `>`
    px1 = margin + int(size * 0.16)
    py1 = margin + int(size * 0.38)
    px2 = margin + int(size * 0.36)
    py2 = margin + int(size * 0.54)
    px3 = px1
    py3 = margin + int(size * 0.70)
    
    chevron_color = (56, 222, 133, 255) # Clean emerald green
    draw.line([px1, py1, px2, py2], fill=chevron_color, width=stroke_w)
    draw.line([px2, py2, px3, py3], fill=chevron_color, width=stroke_w)
    
    # Cursor `_`
    cur_x1 = margin + int(size * 0.46)
    cur_x2 = margin + int(size * 0.70)
    cur_y = py3
    draw.line([cur_x1, cur_y, cur_x2, cur_y], fill=(245, 245, 245, 255), width=stroke_w)
    
    return img

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    iconset_dir = os.path.join(script_dir, "AppIcon.iconset")
    if os.path.exists(iconset_dir):
        shutil.rmtree(iconset_dir)
    os.makedirs(iconset_dir, exist_ok=True)

    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]

    for s, name in sizes:
        icon = create_icon(s)
        icon.save(os.path.join(iconset_dir, name))

    output_icns = os.path.join(script_dir, "AppIcon.icns")
    res = subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", output_icns], capture_output=True, text=True)
    if res.returncode == 0:
        print(f"Generated {output_icns} successfully ({os.path.getsize(output_icns)} bytes)")
        shutil.rmtree(iconset_dir)
    else:
        print(f"Error generating icns: {res.stderr}")

if __name__ == "__main__":
    main()
