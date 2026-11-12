local mainMod = "ALT"
local terminal = "kitty"
local fileManager = "ski"
local browser = "firefox"
SCRIPTS = "/home/admin/user_scripts/"

local function is_target_app_active()
  local w = hl.get_active_window()
  if not w then
    return false
  end
  local class = w.class or ""
  return class == "dusky_tui"
    or class == "wallpaper_selector.py"
    or class == "dusky-papers"
    or class == "factorio"
    or class == "terminal_clipboard.sh"
    or class == "dusky_snapshot_manager.py"
end

local function cond_bind(key, default_dsp, flags)
  hl.bind(key, function()
    if is_target_app_active() then
      hl.dispatch(hl.dsp.pass({ window = "activewindow" }))
    else
      if default_dsp then
        if type(default_dsp) == "function" then
          default_dsp()
        else
          hl.dispatch(default_dsp)
        end
      else
        hl.dispatch(hl.dsp.pass({ window = "activewindow" }))
      end
    end
  end, flags)
end

-- App launchers --
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal), { description = "Launch Terminal" })

hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser), { description = "Launch Browser" })

hl.bind("SUPER + E", hl.dsp.exec_cmd(fileManager), { description = "Launch File Manager" })

hl.bind(
  "CTRL + SHIFT + escape",
  hl.dsp.exec_cmd(terminal .. " --class btop -e btop"),
  { description = "System Monitor" }
)

hl.bind(
  mainMod .. " + P",
  hl.dsp.exec_cmd(
    "pkill rofi; rofi -show power-menu -modi power-menu:" .. SCRIPTS .. "rofi/powermenu.sh -no-fixed-num-lines -i"
  ),
  { description = "Power Menu" }
)

hl.bind("SUPER + P", hl.dsp.exec_cmd("pkill hyprpicker || hyprpicker -a"), { description = "Color Picker" })

hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("rain-clock gui"), { description = "Rain Clock Settings Panel" })

-- Window management --
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close Window" })

hl.bind(
  mainMod .. " + F",
  hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }),
  { description = "Window Maximize" }
)

hl.bind(
  mainMod .." + SHIFT + F",
  hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
  { description = "Window Fullscreen" }
)

hl.bind("SUPER + J", hl.dsp.layout("togglesplit"), { description = "Toggle Window Split" })

hl.bind(
  "SUPER + D",
  hl.dsp.exec_cmd([[
      if hyprctl activewindow | grep -q 'floating: 0'; then
          W=$(hyprctl monitors -j | jq '.[] | select(.focused) | ((.width / .scale) * 0.9) | floor')
          H=$(hyprctl monitors -j | jq '.[] | select(.focused) | ((.height / .scale) * 0.9) | floor')
          hyprctl --batch "dispatch hl.dsp.window.float({action='set'}); dispatch hl.dsp.window.resize({x=${W}, y=${H}, relative=false})"
          hyprctl dispatch "hl.dsp.window.center()"
      else
          hyprctl dispatch "hl.dsp.window.float({action='unset'})"
      fi
  ]]),
  { description = "Smart Float" }
)

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Focus movement --
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }), { description = "Focus Left", repeating = true })

hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }), { description = "Focus Right", repeating = true })

hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }), { description = "Focus Up", repeating = true })

hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }), { description = "Focus Down", repeating = true })

-- Window movement --
hl.bind(
  mainMod .. " + SHIFT + H",
  hl.dsp.window.move({ direction = "l" }),
  { description = "Move Left", repeating = true }
)

hl.bind(
  mainMod .. " + SHIFT + L",
  hl.dsp.window.move({ direction = "r" }),
  { description = "Move right", repeating = true }
)

hl.bind(
  mainMod .. " + SHIFT + K",
  hl.dsp.window.move({ direction = "u" }),
  { description = "Move Up", repeating = true }
)

hl.bind(
  mainMod .. " + SHIFT + J",
  hl.dsp.window.move({ direction = "d" }),
  { description = "Move Down", repeating = true }
)

-- Window resizing --
hl.bind(
  mainMod .. " + Right",
  hl.dsp.window.resize({ x = 30, y = 0, relative = true }),
  { description = "Resize Width +", repeating = true }
)

hl.bind(
  mainMod .. " + Left",
  hl.dsp.window.resize({ x = -30, y = 0, relative = true }),
  { description = "Resize Width -", repeating = true }
)

hl.bind(
  mainMod .. " + up",
  hl.dsp.window.resize({ x = 0, y = -30, relative = true }),
  { description = "Resize Height -", repeating = true }
)

hl.bind(
  mainMod .. " + down",
  hl.dsp.window.resize({ x = 0, y = 30, relative = true }),
  { description = "Resize Height +", repeating = true }
)

-- Workspaces --
hl.bind(
  mainMod .. " + TAB",
  hl.dsp.focus({ workspace = "previous" }),
  { description = "Last Workspace", repeating = true }
)

for i = 1, 10 do
  local key = tostring(i % 10)

  -- Alt + number: Switch workspace on current monitor
  hl.bind(
    "ALT + " .. key,
    hl.dsp.focus({
      workspace = "r~" .. i,
      on_current_monitor = true,
    }),
    { description = "Switch To Workspace " .. i }
  )

  -- Alt + Shift + number: Move window to workspace
  hl.bind(
    "ALT + SHIFT + " .. key,
    hl.dsp.window.move({
      workspace = "r~" .. i,
      follow = false,
    }),
    { description = "Move Window To Workspace " .. i }
  )
end

-- Screenshots --
hl.bind(
  mainMod .. " + S",
  hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]),
  { description = "Screenshot to clipboard" }
)

hl.bind(
  mainMod .. " + SHIFT + S",
  hl.dsp.exec_cmd([[grim -g "$(slurp)" ~/Pictures/Screenshots/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png]]),
  { description = "Save screenshot" }
)

-- Hardware keys --
hl.bind(
  "SUPER + F7",
  hl.dsp.exec_cmd("ddcutil setvcp 10 - 5"),
  { description = "Decrease Monitor Brightness", repeating = true }
)

hl.bind(
  "SUPER + F8",
  hl.dsp.exec_cmd("ddcutil setvcp 10 + 5"),
  { description = "Increase Monitor Brightness", repeating = true }
)

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
  "XF86AudioRaiseVolume",
  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+"),
  { locked = true, repeating = true }
)
hl.bind(
  "XF86AudioLowerVolume",
  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"),
  { locked = true, repeating = true }
)
hl.bind(
  "XF86AudioMute",
  hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
  { locked = true, repeating = true }
)
hl.bind(
  "XF86AudioMicMute",
  hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
  { locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 2%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 2%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Serpantinum --
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("serpantinum reload"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("serpantinum msg toggle clipboard"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("serpantinum msg toggle music"))
hl.bind("SUPER + A", hl.dsp.exec_cmd("serpantinum msg toggle system"))
hl.bind("SUPER + W", hl.dsp.exec_cmd("serpantinum msg toggle wallpaper"))
hl.bind("SUPER + I", hl.dsp.exec_cmd("serpantinum msg toggle settings"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("serpantinum msg toggle launcher"))
hl.bind( "SUPER + SHIFT + L", hl.dsp.exec_cmd("serpantinum lock"), { repeating = true, locked = true })

-- Game mode --
local SUBMAP_MANUAL_PT = "keybinds_disabled"

cond_bind(mainMod .. " + SHIFT + G", function()
  hl.notification.create({ text = "Passthrough Enabled - Press ALT + SHIFT + G exit", timeout = 3000 })
  hl.dispatch(hl.dsp.submap(SUBMAP_MANUAL_PT))
end, { description = "Enabled Game Mode (Disable Keybinds", locked = true })

hl.define_submap(SUBMAP_MANUAL_PT, function()
  hl.bind(mainMod .. " + SHIFT + G", function()
    hl.notification.create({ text = "Passthrough Disabled - Keybinds restored", timeout = 2000 })
    hl.dispatch(hl.dsp.submap("reset"))
  end, { description = "Disable Game Mode (Restore Keybinds)", locked = true })
end)
