--- @since 25.5.31

local M = {
	keys = {
		{ on = "<Esc>", run = "quit", desc = "Quit plugin" },
		{ on = "q", run = "quit", desc = "Quit plugin" },
		
		{ on = "<Down>", run = "down", desc = "Move cursor down" },
		{ on = "<Up>", run = "up", desc = "Move cursor up" },
		{ on = "j", run = "down", desc = "Move cursor down" },
		{ on = "k", run = "up", desc = "Move cursor up" },
		
		{ on = "<Enter>", run = { "enter", "quit" }, desc = "Enter device" },
		{ on = "<Right>", run = { "enter", "quit" }, desc = "Enter device" },
		{ on = "l", run = { "enter", "quit" }, desc = "Enter device" },
		
		{ on = "m", run = "mount", desc = "Mount device" },
		{ on = "u", run = "unmount", desc = "Unmount device" },
	},
}

local SHELL = os.getenv("SHELL") or ""
local HOME = os.getenv("HOME") or ""
local PLUGIN_NAME = "mtp"

local USER_ID = ya.uid()
local USER_NAME = tostring(ya.user_name(USER_ID))
local XDG_RUNTIME_DIR = os.getenv("XDG_RUNTIME_DIR") or ("/run/user/" .. USER_ID)
local GVFS_ROOT_MOUNTPOINT = XDG_RUNTIME_DIR and (XDG_RUNTIME_DIR .. "/gvfs") or (HOME .. "/.gvfs")

-- -- Log file for debugging
-- local LOG_FILE = "/tmp/mtp_debug.log"
-- local function log_to_file(s, ...)
-- 	local file = io.open(LOG_FILE, "a")
-- 	if file then
-- 		file:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. string.format(s, ...) .. "\n")
-- 		file:close()
-- 	end
-- end

---@enum NOTIFY_MSG
local NOTIFY_MSG = {
	CMD_NOT_FOUND = 'Command "%s" not found. Make sure it is installed.',
	MOUNT_SUCCESS = 'Mounted: "%s"',
	MOUNT_ERROR = "Mount error: %s",
	UNMOUNT_SUCCESS = 'Unmounted: "%s"',
	EJECT_SUCCESS = 'Ejected "%s", it can safely be removed',
	DEVICE_IS_DISCONNECTED = "Device is disconnected or not ready.",
	HEADLESS_DETECTED = "MTP.yazi plugin requires a DBUS session.",
}

---@enum SCHEME
local SCHEME = { MTP = "mtp" }

local state = {}
local function set_state(key, value) state[key] = value end
local function get_state(key) return state[key] end

local function error(s, ...)
	local msg = string.format(s, ...)
	ya.notify({ title = PLUGIN_NAME, content = msg, timeout = 3, level = "error" })
end

local function info(s, ...)
	local msg = string.format(s, ...)
	ya.notify({ title = PLUGIN_NAME, content = msg, timeout = 3, level = "info" })
end

local function run_command(cmd, args, _stdin)
	local stdin = _stdin or Command.INHERIT
	local child, cmd_err = Command(cmd)
		:arg(args)
		:env("XDG_RUNTIME_DIR", XDG_RUNTIME_DIR)
		:env("LC_ALL", "C")
		:stdin(stdin)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()

	if not child then return cmd_err, nil end
	local output, out_err = child:wait_with_output()
	if not output then return out_err, nil end
	return nil, output
end

local function is_in_dbus_session()
	local dbus_session = get_state("DBUS_SESSION")
	if dbus_session == nil then
		local cha, _ = fs.cha(Url(XDG_RUNTIME_DIR))
		dbus_session = cha and true or false
		set_state("DBUS_SESSION", dbus_session)
	end
	return dbus_session
end

local function is_cmd_exist(cmd)
	local cmd_found = get_state("CMD_FOUND_" .. cmd)
	if cmd_found == nil then
		local _, output = run_command("which", { cmd })
		cmd_found = output and output.status and output.status.success
		set_state("CMD_FOUND_" .. cmd, cmd_found)
	end
	return cmd_found
end

local function is_folder_exist(path)
	if not path or path == "" then return false end
	local _, output = run_command("test", { "-d", path })
	return output and output.status and output.status.success
end

local function tbl_deep_clone(original)
	if type(original) ~= "table" then return original end
	local copy = {}
	for key, value in pairs(original) do
		copy[tbl_deep_clone(key)] = tbl_deep_clone(value)
	end
	return copy
end

local function is_mountpoint_belong_to_volume(mount, volume)
	return mount.is_shadowed ~= "1"
		and mount.scheme == volume.scheme
		and (
			(mount.uri and mount.uri == volume.uri)
			or (mount.uuid and mount.uuid == volume.uuid)
			or (mount["unix-device"] and mount["unix-device"] == volume["unix-device"])
			or (mount.bus and mount.device and mount.bus == volume.bus and mount.device == volume.device)
			or (mount.name and mount.name == volume.name and mount.scheme == SCHEME.FILE)
		)
end

local function parse_devices(raw_input)
	local volumes = {}
	local mounts = {}
	local current_volume = nil
	local current_mount = nil

	for line in raw_input:gmatch("[^\r\n]+") do
		local clean_line = line:match("^%s*(.-)%s*$")
		local volume_name = clean_line:match("^Volume%(%d+%):%s*(.+)$")
		
		if line:match("^Drive%(%d+%):") then
			current_mount = nil
			current_volume = nil
		elseif volume_name then
			current_mount = nil
			current_volume = { name = volume_name, mounts = {} }
			table.insert(volumes, current_volume)
		elseif clean_line:match("^Mount%(%d+%):") then
			current_mount = nil
			local mount_name = clean_line:match("^Mount%(%d+%):%s*(.+)$")
			local mount_uri = line:match("->%s*(.+)$")
			if not mount_name and mount_uri then mount_name = "Mount" end

			current_mount = { name = mount_name or "", uri = mount_uri or "" }
			if not current_mount.scheme and mount_uri and mount_uri:match("^mtp:") then
				current_mount.scheme = SCHEME.MTP
			end
			table.insert(mounts, current_mount)
		else
			local key, value = clean_line:match("^(%S+)%s*=%s*(.+)$")
			if not key then key, value = clean_line:match("^(%S+)%s*:%s*'(.-)'$") end
			local target = current_mount or current_volume
			if target and key and value then
				if key == "activation_root" then target.uri = value end
				if key ~= "name" or not target[key] then target[key] = value end
			end
			if key == "uuid" and value and current_volume then
				current_volume.encrypted_uuid = value
			end
		end
	end

	for i = #volumes, 1, -1 do
		local v = volumes[i]
		if not v.scheme then
			 if (v.uri and v.uri:match("^mtp:")) or (v.uuid and v.uuid:match("^mtp:")) then
				v.scheme = SCHEME.MTP
			 else v.scheme = SCHEME.FILE end
		end
		for j = #mounts, 1, -1 do
			if is_mountpoint_belong_to_volume(mounts[j], v) then
				table.insert(v.mounts, table.remove(mounts, j))
			end
		end
	end
	for _, m in ipairs(mounts) do
		if m.is_shadowed ~= "1" and m.uri and m.uri:match("^mtp:") then
			m.mounts = { tbl_deep_clone(m) }
			m.scheme = SCHEME.MTP
			table.insert(volumes, m)
		end
	end
	return volumes
end

local function get_mounted_path_impl(device)
	if not device then return nil end
	local uri_to_check = device.uri or (#device.mounts > 0 and device.mounts[1].uri)
	if not uri_to_check then return nil end
	
	local _, res = run_command("gio", { "info", uri_to_check })
	if not res or not res.status.success then return nil end

	for line in res.stdout:gmatch("[^\r\n]+") do
		local path = line:match("^%s*local path: (.+)$")
		if not path then path = line:match("^%s*本地路径: (.+)$") end
		if path then
			path = path:match("^%s*(.-)%s*$")
			if is_folder_exist(path) then return path end
		end
	end
	return nil
end

local function list_mtp_devices()
	local devices = {}
	local _, res = run_command("gio", { "mount", "-li" })
	if res and res.status and res.status.success then
		local status, all_devices = pcall(parse_devices, res.stdout)
		if status then
			for _, d in ipairs(all_devices) do
				if d.scheme == SCHEME.MTP then
					d.cached_is_mounted = (#d.mounts > 0)
					d.cached_path = nil
					if d.cached_is_mounted then
						d.cached_path = get_mounted_path_impl(d)
					end
					table.insert(devices, d)
				end
			end
		end
	end
	return devices
end

local function mount_device(opts)
	local device = opts.device
	local uri = device.uri
	if not uri then return false end
	local _, res = run_command("gio", { "mount", uri })
	if res and res.status and res.status.success then
		info(NOTIFY_MSG.MOUNT_SUCCESS, device.name)
		return true
	elseif res and res.status and res.status.code == 2 then
		return true
	else
		error(NOTIFY_MSG.MOUNT_ERROR, res and res.stderr or "Unknown")
	end
	return false
end

local function unmount_gvfs(device, eject)
	if not device then return true end
	local flag = eject and "-e" or "-u"
	local mounts = device.mounts or { device }
	for _, mount in ipairs(mounts) do
		local uri = mount.uri or device.uri
		if uri then
			 run_command("gio", { "mount", flag, uri })
			 info(eject and NOTIFY_MSG.EJECT_SUCCESS or NOTIFY_MSG.UNMOUNT_SUCCESS, mount.name or device.name)
			 return true
		end
	end
	return false
end

local function jump_to_device_mountpoint_action(device)
	if not device then return end
	local mnt_path = device.cached_path
	if not mnt_path then mnt_path = get_mounted_path_impl(device) end

	if mnt_path then
		ya.emit("cd", { mnt_path, raw = true })
	else
		error(NOTIFY_MSG.DEVICE_IS_DISCONNECTED)
	end
end

local toggle_ui = ya.sync(function(self)
	if self.children then
		Modal:children_remove(self.children)
		self.children = nil
	else
		self.children = Modal:children_add(self, 10)
	end
	if ui.render then ui.render() else ya.render() end
end)

local subscribe = ya.sync(function(self)
	ps.unsub(PLUGIN_NAME .. "-mounts-changed")
	ps.sub(PLUGIN_NAME .. "-mounts-changed", function() ya.emit("plugin", { self._id, "refresh" }) end)
end)

local update_devices = ya.sync(function(self, devices)
	self.devices = devices
	self.cursor = math.max(0, math.min(self.cursor or 0, #self.devices - 1))
	if ui.render then ui.render() else ya.render() end
end)

local active_device = ya.sync(function(self) return self.devices[self.cursor + 1] end)

local update_cursor = ya.sync(function(self, cursor)
	if not self.devices or #self.devices == 0 then
		self.cursor = 0
	else
		self.cursor = ya.clamp(0, self.cursor + cursor, #self.devices - 1)
	end
	if ui.render then ui.render() else ya.render() end
end)

function M:new(area)
	self:layout(area)
	return self
end

function M:layout(area)
	local chunks = ui.Layout()
		:constraints({ ui.Constraint.Percentage(10), ui.Constraint.Percentage(80), ui.Constraint.Percentage(10) })
		:split(area)
	local center = ui.Layout()
		:direction(ui.Layout.HORIZONTAL)
		:constraints({ ui.Constraint.Percentage(10), ui.Constraint.Percentage(80), ui.Constraint.Percentage(10) })
		:split(chunks[2])
	self._area = center[2]
end

function M:entry(job)
	if job.args[1] == "refresh" then
		return update_devices(self.obtain())
	end

	if not is_cmd_exist("gio") then
		error(NOTIFY_MSG.CMD_NOT_FOUND, "gio")
		return
	end
	if not is_in_dbus_session() then
		error(NOTIFY_MSG.HEADLESS_DETECTED)
		return
	end

	toggle_ui()
	update_devices(self.obtain())
	subscribe()

	local tx1, rx1 = ya.chan("mpsc")
	local tx2, rx2 = ya.chan("mpsc")

	function producer()
		while true do
			local idx = ya.which { cands = self.keys, silent = true }
			local cand = self.keys[idx] or { run = {} }
			
			for _, r in ipairs(type(cand.run) == "table" and cand.run or { cand.run }) do
				tx1:send(r)
				if r == "quit" then
					toggle_ui()
					return
				end
			end
		end
	end

	function consumer1()
		while true do
			local run = rx1:recv()
			if not run then
				tx2:send("quit")
				break
			end

			if run == "quit" then
				tx2:send(run)
				break
			elseif run == "up" then
				update_cursor(-1)
			elseif run == "down" then
				update_cursor(1)
			elseif run == "enter" then
				local active = active_device()
				if active then
					jump_to_device_mountpoint_action(active)
				end
			else
				tx2:send(run)
			end
		end
	end

	function consumer2()
		while true do
			local run = rx2:recv()
			if not run or run == "quit" then break end
			
			if run == "mount" then
				self.operate("mount")
			elseif run == "unmount" then
				self.operate("unmount")
			end
		end
	end

	ya.join(producer, consumer1, consumer2)
end

function M:reflow() return { self } end

function M:redraw()
	local rows = {}
	for i, device in ipairs(self.devices or {}) do
		local mount_path = device.cached_path or ""
		-- local style = (i - 1) == self.cursor and ui.Style():fg("blue"):reverse() or ui.Style()
		
		rows[#rows + 1] = ui.Row {
			ui.Line(device.name or "N/A"):style(style),
			ui.Line(device.uri or "N/A"):style(style),
			ui.Line(mount_path):style(style)
		}
	end

	return {
		ui.Clear(self._area),
		ui.Border(ui.Edge.ALL)
			:area(self._area)
			:type(ui.Border.ROUNDED)
			:style(ui.Style():fg("blue"))
			:title(ui.Line("MTP Devices Manager"):align(ui.Align.CENTER)),
		ui.Table(rows)
			:area(self._area:pad(ui.Pad(1, 2, 1, 2)))
			:header(ui.Row({ "Devices", "URI", "Mount Point" }):style(ui.Style():bold()))
			:row(self.cursor)
			:row_style(ui.Style():fg("blue"):underline())
			:widths {
				ui.Constraint.Percentage(15),
				ui.Constraint.Percentage(35),
				ui.Constraint.Percentage(50),
			},
	}
end

function M.obtain()
	return list_mtp_devices()
end

function M.operate(type)
	local active = active_device()
	if not active then return end

	local output_status
	if type == "mount" then
		output_status = mount_device({ device = active })
	elseif type == "unmount" then
		output_status = unmount_gvfs(active, false)
	end

	if output_status then
		update_devices(M.obtain())
	else
		M.fail("Failed to %s device", type)
		update_devices(M.obtain())
	end
end

function M.fail(...) ya.notify { title = PLUGIN_NAME, content = string.format(...), timeout = 10, level = "error" } end
function M:click() end
function M:scroll() end
function M:touch() end
function M:setup(opts) set_state("ROOT_MOUNTPOINT", GVFS_ROOT_MOUNTPOINT) end

return M
