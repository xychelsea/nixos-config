{ pkgs, ... }:
{
  services.jankyborders = {
    enable = true;
    package = pkgs.jankyborders;
    settings = {
      active_color = "0xfff5c2e7";
      inactive_color = "0xff6c7086";
      width = 2.0;
      hidpi = "on";
      style = "round";
      order = "above";
      ax_focus = "on";
    };
  };
}
