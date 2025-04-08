# Autostart wayfire when logging in
function start_wayfire
	if ! pidof "wayfire" > /dev/null
		source ~/.profile
		wayfire > /dev/null 2>&1 &
		set -x WAYLAND_DISPLAY wayland-1
	end
end
