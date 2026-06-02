{pkgs, ...}:
{
  wayland.windowManager.hyprland = {
    configType = "lua";
    enable = true;
    systemd = {
      enable = true;
      variables = [ "--all" ];
    };
  };
}
