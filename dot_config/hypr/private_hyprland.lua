HOME = os.getenv("HOME")

-- Load matugen colors globally (dusky style)
pcall(dofile, HOME .. "/.config/matugen/generated/hyprland-colors.lua")

require("config/env")
require("config/autostart")
require("config/monitors")
require("config/settings")
require("config/keybinds")
require("config/animations")
require("config/layout")
require("config/window_rules")

-- HyprMod managed settings
require("hyprland-gui")
