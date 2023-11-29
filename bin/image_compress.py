#!/usr/bin/env python3

import argparse
import os 
from PIL import Image

# def tinify_compress(input_file, output_file):
#     source = tinify.from_file(input_file)
#     source.to_file(output_file)

def compress_image(input_file, output_file, quality=85):
    # Open an image file
    with Image.open(input_file) as img:
        # Optional: Resize the image
        # img = img.resize((new_width, new_height))

        # Save the image with desired quality
        # 'quality' ranges from 1 (worst) to 95 (best)
        img.save(output_file, 'JPEG', optimize=True, quality=quality)

def commands_parser():
    parser = argparse.ArgumentParser(description='Image resizer', epilog=f'Example: {__file__} -i <input_dir> -o <output_dir>"')
    parser.add_argument('-f','--file', help='input directory', required=False)
    parser.add_argument('-i','--input', help='input directory', required=False)
    parser.add_argument('-o','--output', help='output directory', metavar="[Required]", required=True)
    args = parser.parse_args()
    return args


def main():
    args = commands_parser()
    INPUT_FILE = args.file
    INPUT_DIR = args.input
    OUTPUT_DIR = args.output

    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    if INPUT_FILE:
        output_path = os.path.join(OUTPUT_DIR, INPUT_FILE)
        compress_image(INPUT_FILE, output_path)
        # tinify_compress(INPUT_FILE, output_path)
    elif INPUT_DIR:
        for image_name in [f for f in os.listdir(INPUT_DIR) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]:
            print("---")
            input_path = os.path.join(INPUT_DIR, image_name)
            output_path = os.path.join(OUTPUT_DIR, image_name)
            compress_image(input_path, output_path)
            # tinify_compress(input_path, output_path)

if __name__ == "__main__":
    main()            
