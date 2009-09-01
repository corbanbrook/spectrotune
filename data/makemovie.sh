#! /bin/sh
ffmpeg -r 30 -i frame-%06d.png spectrotune.mp4
