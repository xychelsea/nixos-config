{pkgs, ...}:
{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mainMod" = "SUPER";
      "$HYPRSCRIPTS" = "~/.config/hypr/scripts";
      env = [
        "CLUTTER_BACKEND,wayland"
        "ELECTRON_OZONE_PLATFORM_HINT,wayland"
        "GDK_SCALE,1"
        "GDK_BACKEND,wayland,x11,*"
        "GTK_THEME,Catppuccin:dark"
        "OZONE_PLATFORM,wayland"
        "MOZ_ENABLE_WAYLAND,1"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_QPA_PLATFORMTHEME,qt6ct"
        "QT_QPA_PLATFORMTHEME,qt5ct"
        "QT_STYLE_OVERRIDE,Catppuccin-Dark"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "SDL_VIDEODRIVER,wayland"
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Bibata-Modern-Ice"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
      ];
      input = {
        kb_layout = "us";
        kb_options = "";
        numlock_by_default = true;
        mouse_refocus = false;
        follow_mouse = 1;
        touchpad = {
          natural_scroll = "yes";
          middle_button_emulation = true;
          scroll_factor = 1.0;
        };
        sensitivity = 0;
      };
      binds = {
        workspace_back_and_forth = true;
        allow_workspace_cycles = true;
        pass_mouse_when_bound = false;
      };
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        initial_workspace_tracking = 1;
      };
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
      bind = [
        "$mainMod, RETURN, exec, kitty"
        "$mainMod, A, exec, cursor"
        "$mainMod, B, exec, brave"
        "$mainMod, D, exec, signal-desktop"
        "$mainMod, S, exec, spotify"
        "$mainMod, Q, killactive"
        "$mainMod, F, fullscreen"
        "$mainMod, T, togglefloating"
        "$mainMod, J, togglesplit"
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"
        "$mainMod, G, togglegroup"
        "$mainMod, K, swapsplit"
        "$mainMod CTRL, Q, exec, wlogout"
        "$mainMod CTRL, W, exec, waypaper"
        "$mainMod SHIFT, B, exec, ~/.config/waybar/launch.sh"
        "$mainMod CTRL, B, exec, ~/.config/waybar/toggle.sh"
      ]
      ++ builtins.concatLists (builtins.genList (i:
        let ws = i + 1;
        in [
          "$mainMod, code:1${toString i}, workspace, ${toString ws}"
          "$mainMod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
        ]) 10);
      general = {
        gaps_in = 2;
        gaps_out = 4;
        border_size = 2;
        "col.active_border" = "rgba(f5c2e7ff)";
        "col.inactive_border" = "rgba(6c7086ff)";
        layout = "dwindle";
        resize_on_border = true;
      };
      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 0.9;
        fullscreen_opacity = 1.0;
        blur = {
          enabled = true;
          size = 6;
          passes = 4;
          new_optimizations = "on";
          ignore_opacity = true;
          xray = true;
        };
        shadow = {
          enabled = true;
          range = 30;
          render_power = 3;
          color = "0x66000000";
        };
      };
      exec-once = [
        "hyprctl setcursor Bibata-Modern-Ice 24"
        "waybar"
        "hyprpaper"
      ];
      monitor = "eDP-1,2880x1920@120,0x0,1.5";
    };
    systemd = {
      enable = true;
      variables = [ "--all" ];
    };
  };
}
