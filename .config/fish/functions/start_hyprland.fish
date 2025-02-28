# Autostart wayfire when logging in
function start_hyprland
	if ! pidof "hyprland" > /dev/null
		hyprland > /dev/null 2>&1 &
	end
	set -x WAYLAND_DISPLAY wayland-1
end
