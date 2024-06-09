local wezterm = require('wezterm')
local mux = wezterm.mux
local config = wezterm.config_builder()


-- CONFIG

-- TODO: cross-platform
config.default_domain = 'WSL:Ubuntu'

config.font = wezterm.font('MesloLGS NF')
config.font_size = 11.0

config.color_schemes = require('color_schemes')
config.color_scheme = require('color_schemes.github_dark_dimmed').color_scheme_name

config.command_palette_bg_color = '#2d333b'
config.command_palette_fg_color = config.color_schemes[config.color_scheme].foreground

config.hide_tab_bar_if_only_one_tab = true

config.audible_bell = 'Disabled'
-- config.visual_bell = {
--     fade_in_duration_ms = 30,
--     fade_out_duration_ms = 30,
-- }

config.window_background_opacity = 0.96
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

-- config.initial_cols = 100
-- config.initial_rows = 32

-- Fix error with LSHIFT, LCTRL, etc. jumping forward in neovim (like W) when kanata keyboard remapper is running in WSL+wezterm
config.allow_win32_input_mode = false
config.treat_left_ctrlalt_as_altgr = true


-- EVENTS

wezterm.on('gui-attached', function(domain)
  -- maximize all displayed windows on startup
  local workspace = mux.get_active_workspace()
  for _, window in ipairs(mux.all_windows()) do
    if window:get_workspace() == workspace then
      window:gui_window():maximize()
    end
  end
end)

return config
