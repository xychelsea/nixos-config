local mainMod = "SUPER"
local HYPRSCRIPTS = "~/.config/hypr/scripts"

local function env(k, v)
  hl.env(k, v)
end

env("CLUTTER_BACKEND", "wayland")
env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
env("GDK_SCALE", "1")
env("GDK_BACKEND", "wayland,x11,*")
env("GTK_THEME", "Catppuccin:dark")
env("OZONE_PLATFORM", "wayland")
env("MOZ_ENABLE_WAYLAND", "1")
env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
env("QT_QPA_PLATFORM", "wayland;xcb")
env("QT_QPA_PLATFORMTHEME", "qt6ct")
env("QT_STYLE_OVERRIDE", "Catppuccin-Dark")
env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
env("SDL_VIDEODRIVER", "wayland")
env("XCURSOR_SIZE", "24")
env("XCURSOR_THEME", "Bibata-Modern-Ice")
env("XDG_CURRENT_DESKTOP", "Hyprland")
env("XDG_SESSION_TYPE", "wayland")
env("XDG_SESSION_DESKTOP", "Hyprland")

hl.monitor({
  output = "eDP-1",
  mode = "2880x1920@120",
  position = "0x0",
  scale = 1.5,
})

hl.monitor({
  output = "DP-2",
  mode = "2560x1440@165.08Hz",
  position = "1920x-1280",
  scale = 1,
  transform = 1,
})

hl.config({
  input = {
    kb_layout = "us",
    kb_options = "altwin:swap_alt_win",
    numlock_by_default = true,
    mouse_refocus = false,
    follow_mouse = 1,
    touchpad = {
      natural_scroll = true,
      middle_button_emulation = true,
      scroll_factor = 1.0,
    },
    sensitivity = 0,
  },

  binds = {
    workspace_back_and_forth = true,
    allow_workspace_cycles = true,
    pass_mouse_when_bound = false,
  },

  general = {
    gaps_in = 2,
    gaps_out = 4,
    border_size = 2,
    ["col.active_border"] = "rgba(f5c2e7ff)",
    ["col.inactive_border"] = "rgba(6c7086ff)",
    layout = "dwindle",
    resize_on_border = true,
  },

  decoration = {
    rounding = 10,
    active_opacity = 1.0,
    inactive_opacity = 0.9,
    fullscreen_opacity = 1.0,
    blur = {
      enabled = true,
      size = 6,
      passes = 4,
      new_optimizations = true,
      ignore_opacity = true,
      xray = true,
    },
    shadow = {
      enabled = true,
      range = 30,
      render_power = 3,
      color = "0x66000000",
    },
  },
})

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("cursor"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("brave --password-store=basic"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("signal-desktop"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("slack"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("spotify"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("vlc"))

hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + T", hl.dsp.window.float())

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))

hl.bind(mainMod .. " + G", hl.dsp.group.toggle())

hl.bind(mainMod .. " + CTRL + Q", hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd("waypaper"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("~/.config/waybar/launch.sh"))
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd("~/.config/waybar/toggle.sh"))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

for i = 1, 10 do
  local key = "code:1" .. tostring(i - 1)
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.on("hyprland.start", function()
  hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
  hl.exec_cmd("waybar")
  hl.exec_cmd("hyprpaper")
end)
