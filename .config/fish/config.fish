if status is-interactive
    # Commands to run in interactive sessions can go here
    
    # Disable Fish welcome message
    set -g fish_greeting ""

    # Setup common aliases
    alias ls='eza -la --color=auto --group-directories-first --group'
    alias cat='bat'
    alias lsblk='lsblk -o NAME,LABEL,TYPE,SIZE,MOUNTPOINTS,UUID'
    alias grep='grep --color=auto'
    alias cleanup='yay -Rsnc $(yay -Qqdt)'
    alias vim='nvim'
    alias ssh='env TERM=xterm-256color ssh'
    alias f='fastfetch'
    alias c='clear'
end

# Add user bin directories to PATH
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/bin"

# GO Proxy Setting
set -gx GOPROXY "https://goproxy.cn"

# Use ff scrept (~/.local/bin/ff) to return path
bind \cf ff-insert

# yazi here
bind \cy y

# lazygit here
bind \cg lazygit
