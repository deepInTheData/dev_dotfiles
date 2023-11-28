#!/usr/bin/env python3
from PIL import Image
import argparse

def commands_parser():
    parser = argparse.ArgumentParser(description='Check image size', epilog=f'Example: {__file__} -i <input_dir> -o <output_dir>"')
    parser.add_argument('-i','--input', help='input file', metavar="[Required]", required=True)
    args = parser.parse_args()
    return args

args = commands_parser()
INPUT_FILE = args.input

im = Image.open(INPUT_FILE)
width, height = im.size
im.close()

print(f"{INPUT_FILE} \n\twidth: {width}px \n\theight: {height}px")