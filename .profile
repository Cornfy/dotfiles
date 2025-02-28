# locale
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

# Editor
export EDITOR=nvim
  
# Term
export TERM=alacritty

# Go Proxy
export GOPROXY=https://goproxy.cn 

# Fcitx 5
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx

# GDK
#export GDK_BACKEND=x11

# QT
export QT_QPA_PLATFORM="wayland;xcb"
export QT_QPA_PLATFORMTHEME=qt5ct # install [qt5ct] package

# Clutter
export CLUTTER_BACKEND=wayland

# SDL2
export SDL_VIDEODRIVER="wayland,x11"

# GLFW
# install [glfw] package

# GLEW
# install [glew-wayland]

# Winit
export WINIT_UNIX_BACKEND=x11

# XDG
export XDG_CURRENT_DESKTOP=wayfire
