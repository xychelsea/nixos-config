{ pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    font = "NotoSans Nerd Font 12";
    theme = "/etc/nixos/scripts/config.rasi";
  };
}
