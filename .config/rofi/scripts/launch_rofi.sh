#!/bin/bash

killall -SIGTERM rofi &> /dev/null
rofi -show-icons -show drun
