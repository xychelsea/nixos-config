{ config, pkgs, lib, ... }:
{
  imports = [
    ./modules/bash.nix
    ./modules/cursor.nix
    ./modules/fastfetch.nix
    ./modules/git.nix
    ./modules/hyprland.nix
    ./modules/hyprlock.nix
    ./modules/hyprpaper.nix
    ./modules/kitty.nix
    ./modules/rofi.nix
    ./modules/signal-desktop.nix
    ./modules/starship.nix
    ./modules/waybar.nix
    ./modules/wlogout.nix
    ./modules/xdg.nix
    ./modules/zsh.nix
  ];

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "Catppuccin";
  };
  fonts = {
    fontconfig = {
      enable = true;
    };
  };
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig = {
      "gtk-application-prefer-dark-theme" = 1;
    };
    gtk4.extraConfig = {
      "gtk-application-prefer-dark-theme" = true;
    };
    theme = {
      name = "Catppuccin";
    };
  };
  home = {
    homeDirectory = "/home/xychelsea";
    file = { };
    packages = [ ];
    pointerCursor = {
      gtk = {
        enable = true;
      };
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
      x11 = {
        enable = true;
      };
    };
    sessionVariables = {
      EDITOR = "nvim";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      XCURSOR_SIZE = "24";
      XCURSOR_THEME = "Bibata-Modern-Ice";
    };
    stateVersion = "26.05";
    username = "xychelsea";
  };
}

