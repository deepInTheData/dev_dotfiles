#!/usr/bin/env python3


import yt_dlp
import argparse
import os


def get_youtube_video_link(url, output_dir):
    if "shorts" in url:
        ydl_opts = {
            "quiet": False,
            "no_warnings": False,
            "no_color": False,
            "no_call_home": True,
            "no_check_certificate": True,
            "format": "bestvideo[height<=1920]",
            "outtmpl": os.path.join(output_dir, "%(title)s.%(ext)s"),
        }
    else:
        ydl_opts = {
            "quiet": False,
            "no_warnings": False,
            "no_color": False,
            "no_call_home": True,
            "no_check_certificate": True,
            "format": "bestvideo[height<=1080]",
            "outtmpl": os.path.join(output_dir, "%(title)s.%(ext)s"),
        }
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            dict_meta = ydl.extract_info(url, download=True)
            return dict_meta["url"], dict_meta["duration"]
    except Exception as e:
        print("Failed getting video link from the following video/url:", e.args[0])
    return None, None


def main():
    parser = argparse.ArgumentParser(description="Get YouTube video link and duration")
    parser.add_argument("url", help="YouTube video URL")
    parser.add_argument(
        "--output-dir", help="Download location for the video", required=False
    )
    args = parser.parse_args()
    if not args.output_dir:
        output_dir = "/Users/dphung/Downloads/youtube/"
    else: 
        output_dir = args.output_dir

    video_link, video_duration = get_youtube_video_link(args.url, output_dir)
    print(f"Downloading in {output_dir}")

    if video_link and video_duration:
        print(f"Video Link: {video_link}")
        print(f"Video Duration: {video_duration} seconds")
    else:
        print("Failed to retrieve video link or duration.")


if __name__ == "__main__":
    main()
