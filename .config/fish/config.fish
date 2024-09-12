if status is-interactive
    # Commands to run in interactive sessions can go here
    
    # Disable Fish welcome message
    set -g fish_greeting ""

    # Setup common aliases
    alias ls='ls -la --color=auto'
    alias grep='grep --color=auto'
    alias cleanup='yay -Rsnc $(yay -Qqdt)'
end

# Set Environment
source ~/.profile

# Autostart WayfireWM when logging in
start_wayfire

