{ pkgs, ... }:
{
  programs.aerospace = {
    enable = true;
    launchd = {
      enable = true;
    };
    settings = {
      accordion-padding = 16;
      after-login-command = [ ];
      after-startup-command = [ ];
      automatically-unhide-macos-hidden-apps = false;
      config-version = 2;
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";
      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;
      exec = {
        inherit-env-vars = true;
      };
      gaps = {
        inner = {
          horizontal = 2;
          vertical = 2;
        };
        outer = {
          left = 4;
          bottom = 4;
          top = 4;
          right = 4;
        };
      };
      mode = {
        main = {
          binding = {
            alt-enter = "exec-and-forget open -na kitty";
            alt-b = "exec-and-forget open -na 'Brave Browser'";
            alt-v = "exec-and-forget open -na VLC";
            alt-q = "close --quit-if-last-window";
            alt-l = "focus left";
            alt-r = "focus right";
            alt-d = "focus down";
            alt-u = "focus up";
            alt-1 = "workspace 1";
            alt-2 = "workspace 2";
            alt-3 = "workspace 3";
            alt-4 = "workspace 4";
            alt-5 = "workspace 5";
            alt-6 = "workspace 6";
            alt-7 = "workspace 7";
            alt-8 = "workspace 8";
            alt-9 = "workspace 9";
            alt-shift-1 = "move-node-to-workspace 1";
            alt-shift-2 = "move-node-to-workspace 2";
            alt-shift-3 = "move-node-to-workspace 3";
            alt-shift-4 = "move-node-to-workspace 4";
            alt-shift-5 = "move-node-to-workspace 5";
            alt-shift-6 = "move-node-to-workspace 6";
            alt-shift-7 = "move-node-to-workspace 7";
            alt-shift-8 = "move-node-to-workspace 8";
            alt-shift-9 = "move-node-to-workspace 9";
          };
        };
        service = {
          binding = {
            esc = [ "reload-config" "mode main" ];
            r = [ "flatten-workspace-tree" "mode main" ];
            f = [ "layout floating tiling" "mode main" ];
            backspace = [ "close-all-windows-but-current" "mode main" ];
          };
        };
      };
      on-focused-monitor-changed = [
        "move-mouse monitor-lazy-center"
      ];
      on-window-detected = [
        {
          "if".app-id = "com.apple.systempreferences";
          run = "layout floating";
        }
        {
          "if".app-id = "com.apple.finder";
          run = "layout floating";
        }
      ];
      start-at-login = false;
    };
  };
}
