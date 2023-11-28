#!/usr/bin/env python3
import argparse

def py():
    f = """#!/usr/bin/env python3

import argparse
def commands_parser():
    parser = argparse.ArgumentParser(description='Image resizer', epilog=f'Example: {__file__} -i <input_dir> -o <output_dir>"')
    parser.add_argument('-i','--input', help='input directory', metavar="[Required]", required=True)
    parser.add_argument('-o','--output', help='output directory', metavar="[Required]", required=True)
    parser.add_argument('-w','--webp', help='create .webp file', action='store_true', required=False)
    args = parser.parse_args()    
    return args

def main():    
    args = commands_parser()
    arg_input = args.input
    arg_xx = args.xx
    arg_output = args.output


if __name__ == "__main__":
    main()"""
    print(f)

def commands_parser():
    parser = argparse.ArgumentParser(description='Generate boilerplate', epilog=f'Example: {__file__} -l python"')
    args = parser.parse_args()
    return args


def main():
    args = commands_parser()
    py()

if __name__ == "__main__":
    main()    
