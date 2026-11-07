-- GENERAL / XWAYLAND / GLOBAL SETTINGS

hl.config({
  xwayland = {
    force_zero_scaling = true,
  },
})

--- Firefox: Float "About" Dialog ---
hl.window_rule({
  name = "float-firefox-about",
  match = { title = "^(About Mozilla Firefox)$" },
  float = true,
})

hl.window_rule({
  name = "float-firefox-library",
  match = {
    class = "^(firefox)$",
    title = "^(Library)$",
  },
  float = true,
  size = { 900, 700 },
})

-- Downloads popup
hl.window_rule({
  name = "file-chooser",
  match = { class = "^(ski-chooser)$" },
  float = true,
  center = true,
  size = { 1000, 700 },
})
