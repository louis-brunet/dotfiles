local wezterm = require('wezterm')
local config = wezterm.config_builder()

config.font = wezterm.font('MesloLGS NF')

config.color_schemes = require('color_schemes')

config.color_scheme = require('color_schemes.github_dark_dimmed').color_scheme_name
config.command_palette_bg_color = '#2d333b'
config.command_palette_fg_color = config.color_schemes[config.color_scheme].foreground

config.default_domain = 'WSL:Ubuntu'

config.hide_tab_bar_if_only_one_tab = true

config.audible_bell = 'Disabled'
-- config.visual_bell = {
--     fade_in_duration_ms = 30,
--     fade_out_duration_ms = 30,
-- }

return config
