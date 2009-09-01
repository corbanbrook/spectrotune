#! /bin/sh
ffmpeg -sameq -r 25 -i frame-%06d.png spectrotune.mp4
