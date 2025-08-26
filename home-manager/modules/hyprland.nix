{pkgs, ...}:
{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mainMod" = "SUPER";
      "$HYPRSCRIPTS" = "~/.config/hypr/scripts";
      "$background" = "rgba(121318ff)";
      "$error" = "rgba(ffb4abff)";
      "$error_container" = "rgba(93000aff)";
      "$inverse_on_surface" = "rgba(2f3036ff)";
      "$inverse_primary" = "rgba(495d92ff)";
      "$inverse_surface" = "rgba(e3e2e9ff)";
      "$on_background" = "rgba(e3e2e9ff)";
      "$on_error" = "rgba(690005ff)";
      "$on_error_container" = "rgba(ffdad6ff)";
      "$on_primary" = "rgba(182e60ff)";
      "$on_primary_container" = "rgba(dae2ffff)";
      "$on_primary_fixed" = "rgba(001848ff)";
      "$on_primary_fixed_variant" = "rgba(314578ff)";
      "$on_secondary" = "rgba(2a3042ff)";
      "$on_secondary_container" = "rgba(dde2f9ff)";
      "$on_secondary_fixed" = "rgba(151b2cff)";
      "$on_secondary_fixed_variant" = "rgba(404659ff)";
      "$on_surface" = "rgba(e3e2e9ff)";
      "$on_surface_variant" = "rgba(c5c6d0ff)";
      "$on_tertiary" = "rgba(422741ff)";
      "$on_tertiary_container" = "rgba(fed6f9ff)";
      "$on_tertiary_fixed" = "rgba(2b122bff)";
      "$on_tertiary_fixed_variant" = "rgba(5a3d59ff)";
      "$outline" = "rgba(8f909aff)";
      "$outline_variant" = "rgba(45464fff)";
      "$primary" = "rgba(b2c5ffff)";
      "$primary_container" = "rgba(314578ff)";
      "$primary_fixed" = "rgba(dae2ffff)";
      "$primary_fixed_dim" = "rgba(b2c5ffff)";
      "$scrim" = "rgba(000000ff)";
      "$secondary" = "rgba(c0c6ddff)";
      "$secondary_container" = "rgba(404659ff)";
      "$secondary_fixed" = "rgba(dde2f9ff)";
      "$secondary_fixed_dim" = "rgba(c0c6ddff)";
      "$shadow" = "rgba(000000ff)";
      "$source_color" = "rgba(2f364bff)";
      "$surface" = "rgba(121318ff)";
      "$surface_bright" = "rgba(38393fff)";
      "$surface_container" = "rgba(1e1f25ff)";
      "$surface_container_high" = "rgba(292a2fff)";
      "$surface_container_highest" = "rgba(33343aff)";
      "$surface_container_low" = "rgba(1a1b21ff);";
      "$surface_container_lowest" = "rgba(0d0e13ff)";
      "$surface_dim" = "rgba(121318ff)";
      "$surface_tint" = "rgba(b2c5ffff);";
      "$surface_variant" = "rgba(45464fff)";
      "$tertiary" = "rgba(e1bbdcff)";
      "$tertiary_container" = "rgba(5a3d59ff)";
      "$tertiary_fixed" = "rgba(fed6f9ff)";
      "$tertiary_fixed_dim" = "rgba(e1bbdcff)";
      "$color8" = "$on_primary_fixed";
      "$color11" = "$on_surface";
      env = [
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_QPA_PLATFORMTHEME,qt6ct"
        "QT_QPA_PLATFORMTHEME,qt5ct"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "GDK_SCALE,1"
        "GDK_BACKEND,wayland,x11,*"
        "CLUTTER_BACKEND,wayland"
        "MOZ_ENABLE_WAYLAND,1"
        "XCURSOR_THEME,Bibata-Modern-Ice"
        "XCURSOR_SIZE,24"
        "OZONE_PLATFORM,wayland"
        "ELECTRON_OZONE_PLATFORM_HINT,wayland"
        "SDL_VIDEODRIVER,wayland"
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
      gestures = {
        workspace_swipe = true;
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
        "$mainMod, A, exec, /projects/cursor/cursor"
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
        gaps_in = 10;
        gaps_out = 14;
        border_size = 3;
        "col.active_border" = "$color11";
        "col.inactive_border" = "$color8";
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
