{ pkgs, ... }:
{
  xdg = {
    portal = {
      config = {
        common = {
          default = [
            "gtk"
            "hyprland"
          ];
          "org.freedesktop.impl.portal.Secret" = [
            "oo7-portal"
          ];
        };
      };
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
      ];
      xdgOpenUsePortal = true;
    };
  };
}
