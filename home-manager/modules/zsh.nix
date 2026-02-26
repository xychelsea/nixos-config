{ pkgs, ... }:
{
  programs.zsh = {
    initExtra = ''
if [[ $(tty) == *"pts"* ]]; then
  fastfetch
else
  echo
  if [ -f /bin/qtile ]; then
    echo "Start Qtile X11 with command Qtile"
  fi
  if [ -f /bin/hyprctl ]; then
    echo "Start Hyprland with command Hyprland"
  fi
fi

eval "$(starship init bash)"
    '';
    enable = true;
    enableCompletion = true;
    history = {
      path = "/dev/null";
      save = 0;
      size = 100;
    };
    shellAliases = {
      ls = "eza -a --icons=always";
      ll = "eza -al --icons=always";
      lt = "eza -a --tree --level=1 --icons=always";
      shutdown = "systemctl poweroff";
    };
  };
}
