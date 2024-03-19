#!/usr/bin/env python3

from moviepy.editor import VideoFileClip, AudioFileClip
import argparse
import os


def create_subclip(input_path, start_time, interval):
    input_dir = os.path.dirname(input_path)
    input_filename_without_ext = os.path.splitext(os.path.basename(input_path))[0]

    extension = os.path.splitext(input_path)[1]
    output_file = os.path.join(
        input_dir,
        f"{input_filename_without_ext}_{start_time}_to_{start_time + interval}{extension}",
    )
    print(f"ext {extension}")
    if extension == ".wav" or extension == ".mp3":
        audio_clip = AudioFileClip(input_path)
        subclip = audio_clip.subclip(start_time, start_time + interval)
        subclip.write_audiofile(output_file)
        exit(1)

    else:
        video = VideoFileClip(input_path)
        video = video.subclip(start_time, start_time + interval)

        if extension == ".webm":
            codec = "libvpx"
        elif extension == ".mp4":
            codec = "libx264"
        bitrate = "50000k"  # "50k", "50000k"
        video.write_videofile(
            output_file, codec=codec, bitrate=bitrate, audio_codec="aac"
        )
        video.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="clip a video")
    parser.add_argument("path", help="Video path")
    parser.add_argument("start", help="start", type=int)
    parser.add_argument("interval", help="interval", type=int)
    args = parser.parse_args()

    create_subclip(args.path, args.start, args.interval)
