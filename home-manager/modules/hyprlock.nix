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
          dots_size = 0.33;
          dots_spacing = 0.15;
          dots_center = true;
          dots_rounding = -1;
          inner_color = "rgba(30,30,46,0.5)";
          font_color = "rgb(205,214,244)";
          font_family = "NotoSans Nerd Font, Roboto, Helvetica, Arial, sans-serif";
          outer_color = "rgb(205,214,244)";
          outline_thickness = 3;
          fade_on_empty = true;
          fade_timeout = 3000;
          hide_input = false;
          rounding = 10;
          capslock_color = -1;
          numlock_color = -1;
          bothlock_color = -1;
          invert_numlock = false;
          swap_font_color = false;
          position = "0, -20";
          halign = "center";
          valign = "center";
          shadow_passes = 10;
          shadow_size = 20;
          shadow_color = "rgb(17,17,27)";
          shadow_boost = 1.6;
        }
      ];
      label = [
        {
          monitor = "";
          text = "cmd[update:1000] echo \"$TIME\"";
          color = "rgb(205,214,244)";
          font_size = 55;
          font_family = "NotoSans Nerd Font, Roboto, Helvetica, Arial, sans-serif";
          position = "-100, 70";
          halign = "right";
          valign = "bottom";
          shadow_passes = 5;
          shadow_size = 1000;
        }
      ];
    };
  };
}
