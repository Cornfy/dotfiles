if status is-interactive
    # Commands to run in interactive sessions can go here
    
    # Disable Fish welcome message
    set -g fish_greeting ""

    # Setup common aliases
    alias ls='eza -la --color=auto --group-directories-first --group'
    alias lsblk='lsblk -o NAME,LABEL,TYPE,SIZE,MOUNTPOINTS,UUID'
    alias grep='grep --color=auto'
    alias vim='nvim'
    alias aur='paru'
    alias winer='bwrap-winer'
    alias cleanup='paru -Rsnc (paru -Qdtq)'
    alias ssh='env TERM=xterm-256color ssh'
    alias f='fastfetch'
    alias c='clear'

    # Key bindinds
    bind \cf ff-insert
    bind \cy y
    bind \cg lazygit
end

# Add user bin directories to PATH
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/bin"

# GO Proxy Setting
set -gx GOPROXY "https://goproxy.cn"

# Android SDK
set -gx ANDROID_HOME "$HOME/Android/Sdk"
set -gx ANDROID_SDK_ROOT "$HOME/Android/Sdk"
fish_add_path -g "$ANDROID_HOME/cmdline-tools/latest/bin"
fish_add_path -g "$ANDROID_HOME/platform-tools"
