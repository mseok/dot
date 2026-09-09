-- Initialize Configuration
local wezterm = require("wezterm")

local config = wezterm.config_builder()
local opacity = 0.8

local function appearance_for_window_environment()
    -- wezterm.gui is unavailable when the config is evaluated by the mux
    -- server, so keep a deterministic fallback for that context.
    if wezterm.gui then
        return wezterm.gui.get_appearance()
    end
    return "Dark"
end

local function scheme_for_appearance(appearance)
    if appearance:find("Dark") then
        return "Catppuccin Mocha"
    end
    return "Catppuccin Latte"
end

-- Font
config.font = wezterm.font_with_fallback({
    {
        family = "JetBrainsMono Nerd Font",
        weight = "Regular",
    },
    "Segoe UI Emoji",
})
config.font_size = 24

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
config.default_cursor_style = "BlinkingBar"

-- Colors
config.color_scheme = scheme_for_appearance(appearance_for_window_environment())

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

config.check_for_updates = true
config.check_for_updates_interval_seconds = 86400

return config
