{pkgs, ...}:
{
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        "/etc/nixos/wallpapers/nix-black-4k.png"
      ];
      wallpaper = [
        ",/etc/nixos/wallpapers/nix-black-4k.png"
      ];
      splash = false;
    };
  };
}
