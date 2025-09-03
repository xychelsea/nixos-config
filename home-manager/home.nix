{ config, pkgs, lib, ... }:
{
  imports = [
    ./modules/bash.nix
    ./modules/cursor.nix
    ./modules/fastfetch.nix
    ./modules/hyprland.nix
    ./modules/hyprpaper.nix
    ./modules/kitty.nix
    ./modules/rofi.nix
    ./modules/signal-desktop.nix
    ./modules/starship.nix
    ./modules/waybar.nix
    ./modules/wlogout.nix
    ./modules/xdg.nix
  ];
  home = {
    username = "xychelsea";
    homeDirectory = "/home/xychelsea";
    stateVersion = "25.05";
    packages = [ ];
    file = { };
    pointerCursor = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
    sessionVariables = {
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      EDITOR = "nvim";
      XCURSOR_SIZE = "24";
      XCURSOR_THEME = "Bibata-Modern-Ice";
    };
  };
  fonts.fontconfig.enable = true;
  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin";
    };
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
  };
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "Catppuccin";
  };
}

