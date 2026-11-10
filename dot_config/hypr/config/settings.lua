hl.config({
  general = {
    border_size = 2,
    gaps_in = 6,
    gaps_out = 8,
    float_gaps = 6,
    resize_on_border = true,
    extend_border_grab_area = 30,
    col = {
      -- Only the focused window gets a visible border.
      active_border = primary,
      inactive_border = "rgba(00000000)",
      nogroup_border = "rgba(00000000)",
      nogroup_border_active = secondary,
    },
  },

  decoration = {
    rounding = 0,
    active_opacity = 1.0,
    inactive_opacity = 1.0,

    blur = {
      enabled = true,
      size = 30,
      passes = 3,
      ignore_opacity = true,

      noise = 0.08,
      contrast = 1.5,

      new_optimizations = true,
    },

    shadow = {
      enabled = true,
      range = 20,
      render_power = 3,
      color = shadow or "rgba(1a1a1aee)",
    },

    glow = {
      enabled = false,
      range = 10,
      render_power = 3,
      color = primary_container,
    },
  },

  input = {
    -- Keyboard --
    kb_layout = "us",
    numlock_by_default = false,
    kb_options = "",
    repeat_rate = 25,
    repeat_delay = 180,

    -- Mouse --
    sensitivity = 1.0,
    accel_profile = "flat",
    force_no_accel = false,

    -- Scrolling --
    scroll_method = "2fg",
    scroll_factor = 1.5,

    -- Touchpad --
    touchpad = {
      natural_scroll = true,
      disable_while_typing = true,
      tap_to_click = true,
      drag_lock = 0,
      tap_and_drag = true,
    },

    -- Focus & Window Interaction --
    follow_mouse = 1,
    focus_on_close = 0,
    mouse_refocus = true,
    float_switch_override_focus = 1,
  },

  misc = {
    focus_on_activate = false,
    font_family = "JetBrains Mono",
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    background_color = background,
  },

  group = {
    col = {
      -- Inactive group borders are transparent as well.
      border_active = primary,
      border_inactive = "rgba(00000000)",
      border_locked_active = tertiary,
      border_locked_inactive = "rgba(00000000)",
    },
    groupbar = {
      enabled = true,
      font_family = "",
      font_size = 10,
      font_weight_active = "bold",
      font_weight_inactive = "normal",
      gradients = true,
      height = 20,
      indicator_gap = 2,
      indicator_height = 0,
      stacked = false,
      priority = 3,
      render_titles = true,
      text_offset = 0,
      text_padding = 10,
      rounding = 10,
      rounding_power = 4.0,
      gradient_rounding = 12,
      gradient_rounding_power = 4.0,
      round_only_edges = false,
      gradient_round_only_edges = false,
      text_color = surface,
      text_color_inactive = on_surface,
      text_color_locked_active = on_tertiary,
      text_color_locked_inactive = on_tertiary_container,
      col = {
        active = primary,
        inactive = inverse_on_surface,
        locked_active = tertiary,
        locked_inactive = tertiary_container,
      },
      gaps_in = 6,
      gaps_out = 4,
      keep_upper_gap = true,
      blur = false,
    },
  },
})

hl.config({
  cursor = {
    invisible = false,
    sync_gsettings_theme = true,
    no_hardware_cursors = 2,
    no_break_fs_vrr = 2,
    persistent_warps = true,
    use_cpu_buffer = 2,
  },
})
