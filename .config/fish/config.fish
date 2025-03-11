if status is-interactive
    # Commands to run in interactive sessions can go here
    
    # Disable Fish welcome message
    set -g fish_greeting ""

    # Setup common aliases
    alias ls='eza -la --color=auto --group-directories-first'
    alias lsblk='lsblk -o NAME,LABEL,TYPE,SIZE,MOUNTPOINTS,UUID'
    alias grep='grep --color=auto'
    alias cleanup='yay -Rsnc $(yay -Qqdt)'
    alias vim='nvim'
    alias n='neofetch'
    alias y='yazi'
end

# Set Environment
source ~/.profile

# Autostart WayfireWM when logging in
# start_hyprland
