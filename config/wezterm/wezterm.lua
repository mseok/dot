-- Initialize Configuration
local wezterm = require("wezterm")

local config = wezterm.config_builder()
local opacity = 0.8

local day_start = 7
local night_start = 19

local function mode_for_time()
    local hour = tonumber(os.date("%H"))
    if hour >= day_start and hour < night_start then
        return "Light"
    end
    return "Dark"
end

local function scheme_for_mode(mode)
    if mode == "Dark" then
        return "Catppuccin Mocha"
    end
    return "Catppuccin Latte"
end

local function theme_for_mode(mode)
    if mode == "Dark" then
        return {
            scheme = scheme_for_mode(mode),
            window_frame = {
                active_titlebar_bg = "#1e1e2e",
                inactive_titlebar_bg = "#181825",
                active_titlebar_fg = "#cdd6f4",
                inactive_titlebar_fg = "#a6adc8",
                active_titlebar_border_bottom = "#313244",
                inactive_titlebar_border_bottom = "#181825",
                button_bg = "#181825",
                button_fg = "#a6adc8",
                button_hover_bg = "#313244",
                button_hover_fg = "#cdd6f4",
            },
            tab_bar = {
                inactive_tab_edge = "#313244",
                active_tab = {
                    bg_color = "#313244",
                    fg_color = "#cdd6f4",
                },
                inactive_tab = {
                    bg_color = "#181825",
                    fg_color = "#a6adc8",
                },
                inactive_tab_hover = {
                    bg_color = "#45475a",
                    fg_color = "#cdd6f4",
                },
                new_tab = {
                    bg_color = "#181825",
                    fg_color = "#a6adc8",
                },
                new_tab_hover = {
                    bg_color = "#45475a",
                    fg_color = "#cdd6f4",
                },
            },
        }
    end

    return {
        scheme = scheme_for_mode(mode),
        window_frame = {
            active_titlebar_bg = "#eff1f5",
            inactive_titlebar_bg = "#e6e9ef",
            active_titlebar_fg = "#4c4f69",
            inactive_titlebar_fg = "#6c6f85",
            active_titlebar_border_bottom = "#ccd0da",
            inactive_titlebar_border_bottom = "#e6e9ef",
            button_bg = "#e6e9ef",
            button_fg = "#6c6f85",
            button_hover_bg = "#ccd0da",
            button_hover_fg = "#4c4f69",
        },
        tab_bar = {
            inactive_tab_edge = "#ccd0da",
            active_tab = {
                bg_color = "#ccd0da",
                fg_color = "#4c4f69",
            },
            inactive_tab = {
                bg_color = "#e6e9ef",
                fg_color = "#6c6f85",
            },
            inactive_tab_hover = {
                bg_color = "#dce0e8",
                fg_color = "#4c4f69",
            },
            new_tab = {
                bg_color = "#e6e9ef",
                fg_color = "#6c6f85",
            },
            new_tab_hover = {
                bg_color = "#dce0e8",
                fg_color = "#4c4f69",
            },
        },
    }
end

local function apply_theme_to_window(window)
    local theme = theme_for_mode(mode_for_time())
    local overrides = window:get_config_overrides() or {}
    local current_frame = overrides.window_frame or {}
    local current_colors = overrides.colors or {}
    local current_tab_bar = current_colors.tab_bar or {}

    local needs_update = overrides.color_scheme ~= theme.scheme
        or current_frame.active_titlebar_bg ~= theme.window_frame.active_titlebar_bg
        or current_frame.inactive_titlebar_bg ~= theme.window_frame.inactive_titlebar_bg
        or current_tab_bar.inactive_tab_edge ~= theme.tab_bar.inactive_tab_edge

    if needs_update then
        overrides.color_scheme = theme.scheme
        overrides.window_frame = theme.window_frame
        current_colors.tab_bar = theme.tab_bar
        overrides.colors = current_colors
        window:set_config_overrides(overrides)
    end
end

-- Reapply the same theme through per-window overrides when the configuration
-- is reloaded. This also keeps the native/fancy tab bar in sync with the
-- terminal palette instead of leaving its default dark strip.
wezterm.on("window-config-reloaded", function(window, _pane)
    apply_theme_to_window(window)
end)

-- WezTerm does not emit a callback merely because the wall clock crossed
-- 07:00 or 19:00. Poll once per minute so the terminal changes at the same
-- time as the Neovim and tmux themes.
wezterm.on("update-status", function(window, _pane)
    apply_theme_to_window(window)
end)

local initial_theme = theme_for_mode(mode_for_time())

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
config.status_update_interval = 60 * 1000
config.cursor_blink_rate = 250
config.default_cursor_style = "BlinkingBar"

-- Colors
config.color_scheme = initial_theme.scheme
config.window_frame = initial_theme.window_frame
config.colors = {
    tab_bar = initial_theme.tab_bar,
}

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
