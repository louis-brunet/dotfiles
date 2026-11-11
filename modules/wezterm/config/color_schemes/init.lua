---@alias WeztermColorSchemeConfig table

---@class UserWeztermColorScheme
---@field color_scheme_name string
---@field color_scheme WeztermColorSchemeConfig

local github_dark_dimmed = require('color_schemes.github_dark_dimmed')

local M = {
    [github_dark_dimmed.color_scheme_name] = github_dark_dimmed.color_scheme
}

return M
