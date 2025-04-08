# Autostart wayfire when logging in
function start_hyprland
	if ! pidof "hyprland" > /dev/null
		source ~/.profile
		hyprland > /dev/null 2>&1 &
		set -x WAYLAND_DISPLAY wayland-1
	end
end
