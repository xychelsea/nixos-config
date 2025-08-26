{ pkgs, ... }:
{
  programs.fastfetch = {
    enable = true;
    package = pkgs.fastfetch;
    settings = {
      logo = {
        padding = { top = 2; };
      };
      display = {
        separator = " ➜ ";
      };
      modules = [
        "break"
        {
          type = "title";
          keyWidth = 10;
        }
        "break"
        {
          type = "os";
          key = "{icon} OS ";
          keyColor = "33";
        }
        {
          type = "kernel";
          key = "│ ├ ";
          keyColor = "33";
        }
        {
          type = "packages";
          key = "│ ├󰏖 ";
          keyColor = "33";
        }
        {
          type = "shell";
          key = "│ └ ";
          keyColor = "33";
        }
              {
          type = "wm";
          key = " WM ";
          keyColor = "34";
        }
        {
          type = "lm";
          key = "│ ├󰧨 ";
          keyColor = "34";
        }
        {
          type = "wmtheme";
          key = "│ ├󰉼 ";
          keyColor = "34";
        }
          {
          type = "icons";
          key = "│ ├󰀻 ";
          keyColor = "34";
        }
        {
          type = "cursor";
          key = "│ ├ ";
          keyColor = "34";
        }
        {
          type = "terminal";
          key = "│ ├ ";
          keyColor = "34";
        }
        {
          type = "terminalfont";
          key = "│ ├ ";
          keyColor = "34";
        }
        {
          type = "wallpaper";
          key = "│ └󰸉 ";
          keyColor = "34";
        }
        {
          type = "host";
          key = "󰌢 PC ";
          keyColor = "32";
        }
        {
          type = "cpu";
          key = "│ ├󰻠 ";
          keyColor = "32";
        }
        {
          type = "gpu";
          key = "│ ├󰍛 ";
          keyColor = "32";
        }
              {
          type = "memory";
          key = "│ ├󰑭 ";
          keyColor = "32";
        }
        {
          type = "swap";
          key = "│ ├󰓡 ";
          keyColor = "32";
        }
        {
          type = "disk";
          key = "│ ├󰋊 ";
          keyColor = "32";
        }
        {
          type = "display";
          key = "│ ├󰍹 ";
          keyColor = "32";
        }
        {
          type = "uptime";
          key = "│ └󰥔 ";
          keyColor = "32";
        }
        {
          type = "sound";
          key = " SND";
          keyColor = "36";
        }
              {
          type = "player";
          key = "│ ├󰥠 ";
          keyColor = "36";
        }
        {
          type = "media";
          key = "│ └󰝚 ";
          keyColor = "36";
        }
        "break"
        "break"
      ];
    };
  };
}

