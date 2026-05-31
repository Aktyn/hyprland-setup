-- This file stores code that preserves location and scale of floating windows

local windows_store = {}
local cache_file = os.getenv("HOME") .. "/.cache/hyprland/floating-windows.lua"
local expiration_time = 7 * 24 * 60 * 60 -- 7 days in seconds

local function load_cache()
	local f = io.open(cache_file, "r")
	if f then
		local content = f:read("*a")
		f:close()
		local chunk = load(content)
		if chunk then
			windows_store = chunk() or {}
		end
	end
end

local save_timer = nil

local function perform_save()
	local currentTime = os.time()

	os.execute("mkdir -p " .. os.getenv("HOME") .. "/.cache/hyprland")
	local f = io.open(cache_file, "w")
	if f then
		f:write("return {\n")
		for hash, data in pairs(windows_store) do
			if currentTime - data.timestamp > expiration_time then
				windows_store[hash] = nil
			else
				f:write(
					string.format(
						'  ["%s"] = { x=%d, y=%d, w=%d, h=%d, t=%d },\n',
						hash,
						data.x,
						data.y,
						data.w,
						data.h,
						data.timestamp or 0
					)
				)
			end
		end
		f:write("}\n")
		f:close()
	end
end

local function save_cache()
	if save_timer then
		save_timer:set_enabled(false)
	end

	save_timer = hl.timer(function()
		perform_save()
		save_timer = nil
	end, { timeout = 2000, type = "oneshot" })
end

local function remove_entry(hash)
	if not hash then
		return
	end

	if windows_store[hash] then
		windows_store[hash] = nil
		save_cache()
	end
end

local ignored_classes = {
	"steam",
}

local function getHash(w)
	local class = w.class or ""
	local title = w.title or ""

	-- if there is no title, we can't reliably identify the window, so we skip it
	if title == "" or ignored_classes[class] ~= nil then
		return nil
	end

	local str = class .. "|" .. title
	local h = 5381
	for i = 1, #str do
		h = (h * 33 + string.byte(str, i)) % 4294967296
	end

	local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local hash = ""
	for _ = 1, 6 do
		local digit = h % 64
		hash = b64:sub(digit + 1, digit + 1) .. hash
		h = math.floor(h / 64)
	end

	return hash
end

load_cache()

hl.on("window.close", function(w)
	local windowHash = getHash(w)
	if not windowHash then
		return
	end

	if w and w.floating then
		local x = w.at["x"]
		local y = w.at["y"]
		local sw = w.size["x"]
		local sh = w.size["y"]
		windows_store[windowHash] = { x = x, y = y, w = sw, h = sh, timestamp = os.time() }
		save_cache()
	else
		remove_entry(windowHash)
	end
end)

hl.on("window.open", function(w)
	local hash = getHash(w)
	if not hash then
		return
	end

	local window = windows_store[hash]
	if window then
		hl.dispatch(hl.dsp.window.float({
			action = "enable",
			class = w.class,
			title = w.title,
		}))
		hl.dispatch(hl.dsp.window.resize({
			x = window.w,
			y = window.h,
			relative = false,
			class = w.class,
			title = w.title,
		}))
		hl.dispatch(hl.dsp.window.move({
			x = window.x,
			y = window.y,
			relative = false,
			class = w.class,
			title = w.title,
		}))
	end
end)
