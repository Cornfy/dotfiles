# Autostart wayfire when logging in
function start_wayfire
    if ! pidof "wayfire" > /dev/null
        nohup wayfire > /dev/null 2>&1 &
    end
    set -x WAYLAND_DISPLAY wayland-1
end
