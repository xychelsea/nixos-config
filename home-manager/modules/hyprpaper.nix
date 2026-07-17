{ pkgs, ... }:
{
  services.hyprpaper = {
    enable = true;
    settings = {
      splash = false;
      wallpaper = [
        {
          monitor = "";
          path = "/etc/nixos/wallpapers/nix-black-4k.png";
          fit_mode = "cover";
        }
      ];
    };
  };
}
