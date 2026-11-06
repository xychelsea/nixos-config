{ pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    settings = {
      font = "NotoSans Nerd Font 12";
    };
    font = "NotoSans Nerd Font 12";
    theme = "/etc/nixos/scripts/config.rasi";
  };
}
