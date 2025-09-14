#!/bin/bash

basepath="$HOME/Pictures/ScreenShots"
output="$basepath/IMG_$(date '+%Y%m%d_%H%M%S').png"

mkdir -p  $basepath

grim -g "$(slurp)" - | tee "$output" | wl-copy --type image/png
# grim - | tee "$output" | wl-copy --type image/png
