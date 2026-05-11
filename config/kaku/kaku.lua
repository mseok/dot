local wezterm = require 'wezterm'

-- Keep this file as a thin wrapper around Kaku's bundled defaults.
local function resolve_bundled_config()
  local candidates = {}

  if wezterm.executable_dir then
    table.insert(candidates, wezterm.executable_dir:gsub('MacOS/?$', 'Resources') .. '/kaku.lua')
    table.insert(candidates, wezterm.executable_dir .. '/../../assets/macos/Kaku.app/Contents/Resources/kaku.lua')
  end

  table.insert(candidates, '/Applications/Kaku.app/Contents/Resources/kaku.lua')

  local home = os.getenv('HOME') or ''
  if home ~= '' then
    table.insert(candidates, home .. '/Applications/Kaku.app/Contents/Resources/kaku.lua')
  end

  for _, candidate in ipairs(candidates) do
    local file = io.open(candidate, 'r')
    if file then
      file:close()
      return candidate
    end
  end

  return nil
end

local config = {}
local bundled = resolve_bundled_config()

if bundled then
  local ok, loaded = pcall(dofile, bundled)
  if ok and type(loaded) == 'table' then
    config = loaded
  else
    wezterm.log_error('Kaku: failed to load bundled defaults from ' .. bundled)
  end
else
  wezterm.log_error('Kaku: bundled defaults not found')
end

config.default_cursor_style = 'SteadyBlock'

return config
