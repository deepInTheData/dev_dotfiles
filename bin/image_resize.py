#!/usr/bin/env python3
from PIL import Image
import os
import re
import argparse


"""
Reference: https://medium.com/@allenhubert22/automated-image-resizing-for-web-development-with-python-c88add053d5

Generates:
`
<picture>
    <source srcset="PLACEHOLDER_xs.webp 1x, PLACEHOLDER_xs.jpg 1x" media="(max-width: 400px)">
    <source srcset="PLACEHOLDER_sm.webp 1x, PLACEHOLDER_sm.jpg 1x" media="(max-width: 640px)">
    <source srcset="PLACEHOLDER_md.webp 1x, PLACEHOLDER_md.jpg 1x" media="(max-width: 768px)">
    <source srcset="PLACEHOLDER_lg.webp 1x, PLACEHOLDER_lg.jpg 1x" media="(min-width: 769px)">
    <img src="PLACEHOLDER_lg.jpg" alt="PLACEHOLDER">
</picture>
`
"""

def commands_parser():
    parser = argparse.ArgumentParser(description='Image resizer', epilog=f'Example: {__file__} -i <input_dir> -o <output_dir>"')
    parser.add_argument('-i','--input', help='input directory', metavar="[Required]", required=True)
    parser.add_argument('-o','--output', help='output directory', metavar="[Required]", required=True)
    parser.add_argument('-w','--webp', help='create .webp file', action='store_true', required=False)
    parser.add_argument('-b','--breakpoints', help='breakpoints comma-seperated', required=False)
    args = parser.parse_args()
    return args

args = commands_parser()
INPUT_DIR = args.input
OUTPUT_DIR = args.output
WEBP = args.webp

# Parameters
QUALITY = 85  # Adjust as needed

#BREAKPOINTS = {"xs": 400, "sm": 640, "md": 768, "lg": 1024, "xl": 1280}
if args.breakpoints:
    BREAKPOINTS = {bp: int(bp) for bp in args.breakpoints.split(",")}
else:
    BREAKPOINTS = {"640": 640}

def name_sanitizer(name):
    name = re.sub(r"\s+", "-", name)
    return re.sub(r"-+", "-", name)

def resize_image(input_path, output_path, breakpoint, ext, has_alpha, width, height):
    max_width = BREAKPOINTS[breakpoint]
    # If the image's width is less than the breakpoint, skip it.
    if width <= max_width:
        return False
    aspect_ratio = height / width
    new_width = max_width
    new_height = int(aspect_ratio * max_width)
    img = Image.open(input_path)
    img = img.resize((new_width, new_height), Image.LANCZOS)

    if output_path: 
        if has_alpha or ext == ".png":
            bg = Image.new("RGB", img.size, (255, 255, 255))
            bg.paste(img, mask=img.split()[3])
            img = bg            
            if WEBP:
                img.convert("RGB").save(
                    output_path.replace(".png", ".webp"), "WEBP", optimize=True, quality=QUALITY
                )            
            else:
                img.convert("RGB").save(
                    output_path.replace(".png", ".jpg"), "JPEG", optimize=True, quality=QUALITY
                )                    
                # img.save(output_path.replace(".png", ".jpg"), "JPEG", optimize=True, quality=QUALITY)
        else:
            if WEBP:
                img.save(output_path.replace(".jpg", ".webp"), "WEBP", optimize=True, quality=QUALITY)
            else:
                img.save(output_path, "JPEG", optimize=True, quality=QUALITY)

    img.close()
    return True

def to_jpeg(image_path, output_image_path):
    img = Image.open(image_path)

    # Check if image has alpha channel
    if img.mode == 'RGBA':
        # Create a new image with white background
        bg = Image.new("RGB", img.size, (255, 255, 255))
        # Paste the image on the background
        bg.paste(img, mask=img.split()[3])
        img = bg
    img.save(output_image_path.replace(".png", ".jpg"), "JPEG", optimize=True, quality=QUALITY)

def main():
    for image_name in os.listdir(INPUT_DIR):  # Loop through all images
        input_path = os.path.join(INPUT_DIR, image_name)
        # Make sure its a png or jpeg type file
        if not os.path.isfile(input_path):
            continue
        ext = os.path.splitext(image_name)[1].lower()
        if ext not in [".jpg", ".jpeg", ".png"]:
            continue

        sanitized_name = name_sanitizer(os.path.splitext(image_name)[0])
        os.makedirs(OUTPUT_DIR, exist_ok=True)

        # Check for alpha/transparency in image
        # See https://pillow.readthedocs.io/en/stable/handbook/concepts.html
        img = Image.open(input_path)
        width, height = img.size
        has_alpha = img.mode == "RGBA" or "A" in img.getbands()
        img.close()

        # make a copy in output directory
        output_image_path = os.path.join(
            OUTPUT_DIR, f"{sanitized_name}{ext}"
        )
        to_jpeg(input_path, output_image_path)

        bps = list(BREAKPOINTS.items())
        for (bp, bp_width) in bps:
            output_image_path = os.path.join(
                OUTPUT_DIR, f"{sanitized_name}_{bp}{ext}"
            )

            result = resize_image(input_path, output_image_path, bp, ext, has_alpha, width, height)
            if result == False:
                break
            

if __name__ == "__main__":
    main()
    template = """
<picture>
    <source srcset="PLACEHOLDER_xs.webp 1x, PLACEHOLDER_xs.jpg 1x" media="(max-width: 400px)">
    <source srcset="PLACEHOLDER_sm.webp 1x, PLACEHOLDER_sm.jpg 1x" media="(max-width: 640px)">
    <source srcset="PLACEHOLDER_md.webp 1x, PLACEHOLDER_md.jpg 1x" media="(max-width: 768px)">
    <source srcset="PLACEHOLDER_lg.webp 1x, PLACEHOLDER_lg.jpg 1x" media="(min-width: 769px)">
    <img src="PLACEHOLDER_lg.jpg" alt="PLACEHOLDER">
</picture>
"""
    print(template)

