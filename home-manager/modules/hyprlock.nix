{pkgs, ...}:
{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        ignore_empty_input = true;
        hide_cursor = true;
      };
      background = {
        path = "screenshot";
        blur_passes = 3;
        blur_size = 8;
      };
      input-field = [
        {
          monitor = "";
          size = "200, 50";
          outline_thickness = 3;
          dots_size = 0.33;
          dots_spacing = 0.15;
          dots_center = true;
          dots_rounding = -1;
          outer_color = "rgb(255,255,255)";
          inner_color = "rgb(91,96,120)";
          font_color = "rgb(255,255,255)";
          fade_on_empty = true;
          fade_timeout = 3000;
          invert_numlock = false;
          swap_font_color = false;
          halign = "center";
          shadow_passes = 10;
          shadow_size = 20;
          shadow_color = "rgb(0,0,0)";
          shadow_boost = 1.6;
        }
      ];
    };
  };
}
