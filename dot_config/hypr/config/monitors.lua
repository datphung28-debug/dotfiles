hl.monitor({
  output = "HDMI-A-1",
  mode = "2560x1440@144",
  position = "0x0",
  scale = 1.0,
})

hl.monitor({
  output = "eDP-1",
  mode = "1920x1080@120",
  position = "320x1440",
  scale = 1.0,
})

for i = 1, 10 do
  local monitor_name = (i % 2 == 1) and "eDP-1" or "HDMI-A-1"
  hl.workspace_rule({
    workspace = tostring(i),
    monitor = monitor_name,
    persistent = true,
  })
end
