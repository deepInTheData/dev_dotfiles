#!/usr/bin/env python3

import io
import os 
import argparse

from PIL import Image
import rembg

def commands_parser():
    parser = argparse.ArgumentParser(description='Image resizer', epilog=f'Example: {__file__} -i <input_dir> -o <output_dir>"')
    parser.add_argument('-f','--file', help='input directory', required=False)
    parser.add_argument('-i','--input', help='input directory', required=False)
    parser.add_argument('-o','--output', help='output directory', metavar="[Required]", required=True)
    args = parser.parse_args()
    return args


def remove_bg(input_file, output_file):
    print(f"Removing background from {input_file}")
    with Image.open(input_file) as img:
        # Convert the image to bytes
        img_bytes = io.BytesIO()
        img.save(img_bytes, format=img.format)
        
        # Remove the background
        output_bytes = rembg.remove(img_bytes.getvalue())

        # Convert the bytes back to an image
        result_img = Image.open(io.BytesIO(output_bytes))

        # Save the result
        result_img.save(output_file, format='PNG')


def main():
    args = commands_parser()
    INPUT_FILE = args.file
    INPUT_DIR = args.input
    OUTPUT_DIR = args.output

    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    if INPUT_FILE:
        output_path = os.path.join(OUTPUT_DIR, INPUT_FILE)
        remove_bg(INPUT_FILE, output_path)
    elif INPUT_DIR:
        for image_name in os.listdir(INPUT_DIR):
            input_path = os.path.join(INPUT_DIR, image_name)
            output_path = os.path.join(OUTPUT_DIR, image_name)
            remove_bg(input_path, output_path)

if __name__ == "__main__":
    main()            