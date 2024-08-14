-- Initialize Configuration
local wezterm = require("wezterm")

local config = wezterm.config_builder()
local opacity = 0.7

function scheme_for_appearance(appearance)
    if appearance:find "Dark" then
        return "Catppuccin Mocha"
    else
        return "Catppuccin Latte"
    end
end

-- Font
config.font = wezterm.font_with_fallback({
    {
        family = "JetBrainsMono Nerd Font",
        weight = "Regular",
    },
    "Segoe UI Emoji",
})
config.font_size = 18

-- Window
config.initial_rows = 45
config.initial_cols = 180
config.window_decorations = "RESIZE"
config.window_background_opacity = opacity
config.window_close_confirmation = "NeverPrompt"
config.win32_system_backdrop = "Acrylic"
config.max_fps = 144
config.animation_fps = 60
config.cursor_blink_rate = 250

-- Colors
-- config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())
config.color_scheme = scheme_for_appearance("Dark")

-- Shell
config.default_prog = { "zsh" }

-- Tabs
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.show_tab_index_in_tab_bar = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = true

-- Keybindings
config.keys = {}

return config
