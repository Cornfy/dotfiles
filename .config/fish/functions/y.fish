function y
    set tmp (mktemp)
    yazi $argv --cwd-file="$tmp" < /dev/tty
    if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
        commandline -f repaint
    end
    rm -f -- "$tmp"
end
