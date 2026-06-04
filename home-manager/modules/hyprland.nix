{pkgs, ...}:
{
  wayland.windowManager.hyprland = {
    configType = "lua";
    enable = true;
    extraConfig = builtins.readFile ./hyprland.lua;
    systemd = {
      enable = true;
      variables = [ "--all" ];
    };
  };
}
