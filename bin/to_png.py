#!/usr/bin/env python3
import argparse
from pathlib import Path
from PIL import Image

def convert_webp_to_png(input_path, output_dir):
    """
    Converts a .webp file to .png format or all .webp files in a directory.
    """
    input_path = Path(input_path)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)  # Create output directory if it doesn't exist
    
    if input_path.is_file() and input_path.suffix == '.webp':
        # Process a single file
        output_file = output_dir / (input_path.stem + '.png')
        with Image.open(input_path) as img:
            img.save(output_file, 'PNG')
        print(f"Converted {input_path} to {output_file}")
    elif input_path.is_dir():
        # Process all .webp files in the directory
        for webp_file in input_path.glob('*.webp'):
            output_file = output_dir / (webp_file.stem + '.png')
            with Image.open(webp_file) as img:
                img.save(output_file, 'PNG')
            print(f"Converted {webp_file} to {output_file}")
    else:
        print("The input path is not a .webp file or a directory.")

def main():
    parser = argparse.ArgumentParser(description='Convert .webp images to .png format.')
    parser.add_argument('input', help='Input .webp file or directory containing .webp files')
    parser.add_argument('output_dir', help='Output directory for .png files', nargs='?', default=Path.cwd())


    
    args = parser.parse_args()
    
    convert_webp_to_png(args.input, args.output_dir)

if __name__ == '__main__':
    main()

