{ pkgs, ... }:
{
  programs.waybar = {
    enable = true;
    settings = [
      {
        layer = "top";
        position = "top";
        margin-top = 14;
        margin-bottom = 0;
        margin-left = 14;
        margin-right = 14;
        pacing = 0;
        "hyprland/workspaces" = {
          "on-scroll-up" = "hyprctl dispatch workspace r-1";
          "on-scroll-down" = "hyprctl dispatch workspace r+1";
          "on-click" = "activate";
          "active-only" = false;
          "all-outputs" = true;
          "format" = "{}";
          "format-icons" = {
            "urgent" = "";
            "active" = "";
            "default" = "";
          };
          "persistent-workspaces" = {
            "*" = 5;
          };
        };
        "wlr/taskbar" = {
          "format" = "{icon}";
          "icon-size" = 18;
          "tooltip-format" = "{title}";
          "on-click" = "activate";
          "on-click-middle" = "close";
          "ignore-list" = ["Alacritty" "kitty"];
          "app_ids-mapping" = {
            "firefoxdeveloperedition" = "firefox-developer-edition";
          };
          "rewrite" = {
            "Firefox Web Browser" = "Firefox";
            "Foot Server" = "Terminal";
          };
        };
        "hyprland/window" = {
          "max-length" = 60;
          "rewrite" = {
            "(.*) - Brave" = "$1";
            "(.*) - Chromium" = "$1";
            "(.*) - Brave Search" = "$1";
            "(.*) - Outlook" = "$1";
            "(.*) Microsoft Teams" = "$1";
          };
          "separate-outputs" = true;
        };
        "custom/empty" = {
          "format" = "";
        };
        "custom/wallpaper" = {
          "format" = "";
          "on-click" = "bash -c waypaper &";
          "tooltip-format" = "Select a wallpaper";
        };
        "custom/appmenu" = {
          "format" = "󱄅";
          "on-click" = "sleep 0.2; rofi -show drun -replace";
          "tooltip-format" = "Open the application launcher";
        };
        "custom/exit" = {
          "format" = "";
          "on-click" = "/etc/nixos/scripts/logout.sh";
          "tooltip-format" = "Power menu";
        };
        "custom/notification" = {
          "tooltip-format" = "Notifications";
          "format" = "{icon}";
          "format-icons" = {
            "notification" = "<span rise='8pt'><span foreground='red'><sup></sup></span></span>";
            "none" = "";
            "dnd-notification" = "<span rise='8pt'><span foreground='red'><sup></sup></span></span>";
            "dnd-none" = "";
            "inhibited-notification" = "<span rise='8pt'><span foreground='red'><sup></sup></span></span>";
            "inhibited-none" = "";
            "dnd-inhibited-notification" = "<span rise='8pt'><span foreground='red'><sup></sup></span></span>";
            "dnd-inhibited-none" = "";
          };
          "return-type" = "json";
          "exec-if" = "which swaync-client";
          "exec" = "swaync-client -swb";
          "on-click" = "swaync-client -t -sw";
          "on-click-right" = "swaync-client -d -sw";
          "escape" = true;
        };
        "custom/hyprshade" = {
          "format" = "󰃟";
          "tooltip-format" = "Toggle Screen Shader";
          "on-click" = "sleep 0.5; ~/etc/nixos/scripts/hyprshade.sh";
          "on-click-right" = "sleep 0.5; ~/etc/nixos/scripts/hyprshade.sh rofi";
        };
        "custom/hypridle" = {
          "format" = "";
          "return-type" = "json";
          "escape" = true;
          "exec-on-event" = true;
          "interval" = 60;
          "exec" = "~/etc/nixos/scripts/hypridle.sh status";
          "on-click" = "~/etc/nixos/scripts/hypridle.sh toggle";
        };
        "keyboard-state" = {
          "numlock" = true;
          "capslock" = true;
          "format" = "{name} {icon}";
          "format-icons" = {
            "locked" = "";
            "unlocked" = "";
          };
        };
        "tray" = {
          "icon-size" = 21;
          "spacing" = 10;
        };
        "custom/system" = {
          "format" = "";
          "tooltip" = false;
        };
        "cpu" = {
          "format" = "󰻠 {usage}% ";
        };
        "memory" = {
          "format" = "󰑭 {}% ";
        };
        "disk" = {
          "interval" = 30;
          "format" = "󰋊 {percentage_used}% ";
          "path" = "/";
        };
        "group/tools" = {
          "orientation" = "inherit";
          "drawer" = {
            "transition-duration" = 300;
            "children-class" = "not-memory";
            "transition-left-to-right" = false;
          };
          "modules" = [
            "custom/tools"
            "custom/cliphist"
            "custom/hypridle"
            "custom/hyprshade"
          ];
        };
        "group/settings" = {
          "orientation" = "inherit";
          "drawer" = {
            "transition-duration" = 300;
            "children-class" = "not-memory";
            "transition-left-to-right" = true;
          };
          "modules" = [
            "custom/settings"
            "custom/wallpaper"
          ];
        };
        "network" = {
          "format" = "{ifname}";
          "format-wifi" = " {essid} ({signalStrength}%)";
          "format-ethernet" = "  {ifname}";
          "format-disconnected" = "Disconnected ⚠";
          "tooltip-format" = " {ifname} via {gwaddri}";
          "tooltip-format-wifi" = "  {ifname} @ {essid}\nIP: {ipaddr}\nStrength: {signalStrength}%\nFreq: {frequency}MHz\nUp: {bandwidthUpBits} Down: {bandwidthDownBits}";
          "tooltip-format-ethernet" = " {ifname}\nIP: {ipaddr}\n up: {bandwidthUpBits} down: {bandwidthDownBits}";
          "tooltip-format-disconnected" = "Disconnected";
          "max-length" = 50;
        };
        "battery" = {
          "states" = {
            "good" = 95;
            "warning" = 30;
            "critical" = 15;
          };
          "format" = "{icon} {capacity}%";
          "format-charging" = " {capacity}%";
          "format-plugged" = " {capacity}%";
          "format-alt" = "{icon} {time}";
          "format-icons" = [
            " "
            " "
            " "
            " "
            " "
          ];
        };
        "power-profiles-daemon" = {
          "format" = "{icon}";
          "tooltip-format" = "Power profile: {profile}\nDriver: {driver}";
          "tooltip" = true;
          "format-icons" = {
            "default" = "";
            "performance" = "";
            "balanced" = "";
            "power-saver" = "";
          };
        };
        "pulseaudio" = {
          "format" = "{icon}  {volume}%";
          "format-bluetooth" = "{volume}% {icon} {format_source}";
          "format-bluetooth-muted" = " {icon} {format_source}";
          "format-muted" = " {format_source}";
          "format-source" = "{volume}% ";
          "format-source-muted" = "";
          "format-icons" = {
            "headphone" = " ";
            "hands-free" = " ";
            "headset" = " ";
            "phone" = " ";
            "portable" = " ";
            "car" = " ";
            "default" = [
              ""
              ""
              ""
            ];
          };
          "on-click" = "pavucontrol";
        };
        "bluetooth" = {
          "format" = " {status}";
          "format-disabled" = "";
          "format-off" = "";
          "interval" = 30;
          "on-click" = "blueman-manager";
          "format-no-controller" = "";
        };
        "user" = {
          "format" = "{user}";
          "interval" = 60;
          "icon" = false;
        };
        "backlight" = {
          "format" = "{icon} {percent}%";
          "format-icons" = [
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
          ];
          "scroll-step" = 1;
        };
        "modules-left" = [
          "custom/appmenu"
          "hyprland/window"
          "custom/empty"
        ];
        "modules-center" = [
          "hyprland/workspaces"
        ];
        "modules-right" = [
          "pulseaudio"
          "bluetooth"
          "network"
          "battery"
          "power-profiles-daemon"
          "disk"
          "cpu"
          "memory"
          "group/tools"
          "tray"
          "custom/notification"
          "custom/exit"
          "clock"
        ];
      }
    ];
    style = ''
* {
    font-family: "NotoSans Nerd Font", Roboto, Helvetica, Arial, sans-serif;
    font-weight: bold;
    border: none;
    border-radius: 0px;
}

window#waybar {
    background-color: rgba(0,0,0,0.8);
    border-bottom: 0px solid #ffffff;
    background: transparent;
    transition-property: background-color;
    transition-duration: .5s;
}

#workspaces {
    background: #ffffff;
    margin: 2px 1px 3px 1px;
    padding: 0px 1px;
    border-radius: 15px;
    border: 0px;
    font-weight: bold;
    font-style: normal;
    opacity: 0.7;
    font-size: 16px;
    color: #000000;
}

#workspaces button {
    padding: 0px 5px;
    margin: 4px 3px;
    border-radius: 15px;
    border: 0px;
    color: #000000;
    background-color: #ffffff;
    transition: all 0.3s ease-in-out;
    opacity: 0.4;
}

#workspaces button.active {
    color: #000000;
    background: #ffffff;
    border-radius: 15px;
    min-width: 40px;
    transition: all 0.3s ease-in-out;
    opacity:1.0;
}

#workspaces button:hover {
    color: #000000;
    background: #ffffff;
    border-radius: 15px;
    opacity:0.7;
}

tooltip {
    border-radius: 16px;
    background-color: #ffffff;
    opacity: 0.9;
    padding: 20px;
    margin: 0px;
}

tooltip label {
    color: #000000;
}

#window {
    background: #ffffff;
    margin: 5px 15px 5px 0px;
    padding: 2px 10px 0px 10px;
    border-radius: 12px;
    color: #000000;
    font-size: 16px;
    font-weight: normal;
    opacity: 0.8;
}

window#waybar.empty #window {
    background-color:transparent;
}

#taskbar {
    background: #ffffff;
    margin: 3px 15px 3px 0px;
    padding:0px;
    border-radius: 15px;
    font-weight: normal;
    font-style: normal;
    opacity:0.8;
    border: 3px solid #ffffff;
}

#taskbar button {
    margin:0;
    border-radius: 15px;
    padding: 0px 5px 0px 5px;
}

#taskbar.empty {
    background:transparent;
    border:0;
    padding:0;
    margin:0;
}

.modules-left > widget:first-child > #workspaces {
    margin-left: 0;
}

.modules-right > widget:last-child > #workspaces {
    margin-right: 0;
}

#custom-brave,
#custom-browser,
#custom-keybindings,
#custom-outlook,
#custom-filemanager,
#custom-teams,
#custom-calculator,
#custom-windowsvm,
#custom-settings,
#custom-wallpaper,
#custom-system,
#custom-hyprshade,
#custom-hypridle,
#custom-tools,
#custom-quicklink_chromium,
#custom-quicklink_edge,
#custom-quicklink_firefox,
#custom-quicklink_browser,
#custom-quicklink_filemanager,
#custom-quicklink_email,
#custom-quicklink_thunderbird,
#custom-quicklink_calculator,
#custom-quicklink1,
#custom-quicklink2,
#custom-quicklink3,
#custom-quicklink4,
#custom-quicklink5,
#custom-quicklink6,
#custom-quicklink7,
#custom-quicklink8,
#custom-quicklink9,
#custom-quicklink10,
#custom-waybarthemes {
    margin-right: 16px;
    font-size: 20px;
    font-weight: bold;
    opacity: 0.8;
    color: #ffffff;
}

#custom-quicklink_chromium,
#custom-quicklink_edge,
#custom-quicklink_firefox,
#custom-quicklink_browser,
#custom-quicklink_filemanager,
#custom-quicklink_email,
#custom-quicklink_thunderbird,
#custom-quicklink_calculator,
#custom-quicklink1,
#custom-quicklink2,
#custom-quicklink3,
#custom-quicklink4,
#custom-quicklink5,
#custom-quicklink6,
#custom-quicklink7,
#custom-quicklink8,
#custom-quicklink9,
#custom-quicklink10 {
    margin-right: 18px;
}

#custom-tools {
    margin-right:12px;
}

#custom-hypridle.active {
    color: #ffffff;
}

#custom-hypridle.notactive {
    color: #dc2f2f;
}

#idle_inhibitor {
    margin-right: 15px;
    font-size: 22px;
    font-weight: bold;
    opacity: 0.8;
    color: #ffffff;
}

#idle_inhibitor.activated {
    margin-right: 15px;
    font-size: 20px;
    font-weight: bold;
    opacity: 0.8;
    color: #dc2f2f;
}

#custom-appmenu {
    background-color: #ffffff;
    font-size: 16px;
    color: #000000;
    border-radius: 15px;
    padding: 0px 10px 0px 10px;
    margin: 3px 17px 3px 0px;
    opacity:0.8;
    border:3px solid #ffffff;
}

#custom-notification {
    margin: 0px 13px 0px 0px;
    padding:0px;
    font-size: 20px;
    color: #ffffff;
    opacity: 0.8;
}

#custom-exit {
    margin: 0px 13px 0px 0px;
    padding: 0px;
    font-size: 20px;
    color: #ffffff;
    opacity: 0.8;
}

#custom-updates {
    background-color: #ffffff;
    font-size: 16px;
    color: #000000;
    border-radius: 15px;
    padding: 2px 10px 0px 10px;
    margin: 5px 15px 5px 0px;
    opacity:0.8;
}

#custom-updates.green {
    background-color: #ffffff;
}

#custom-updates.yellow {
    background-color: #ff9a3c;
    color: #ffffff;
}

#custom-updates.red {
    background-color: #dc2f2f;
    color: #ffffff;
}

#disk,#cpu,#memory {
    margin: 0px;
    padding: 0px;
    font-size: 16px;
    color: #ffffff;
}

#memory {
    margin-right:10px;
}

#power-profiles-daemon {
    margin: 0px 13px 0px 0px;
    padding: 0px;
    font-size: 16px;
    color: #ffffff;
}

#clock {
    background-color: #ffffff;
    font-size: 16px;
    color: #000000;
    border-radius: 15px;
    padding: 1px 10px 0px 10px;
    margin: 3px 0px 3px 0px;
    opacity:0.8;
    border:3px solid #ffffff;
}

#backlight {
    background-color: #ffffff;
    font-size: 16px;
    color: #000000;
    border-radius: 15px;
    padding: 2px 10px 0px 10px;
    margin: 5px 15px 5px 0px;
    opacity:0.8;
}

#pulseaudio {
    background-color: #ffffff;
    font-size: 16px;
    color: #000000;
    border-radius: 15px;
    padding: 2px 10px 0px 10px;
    margin: 5px 15px 5px 0px;
    opacity:0.8;
}

#pulseaudio.muted {
    background-color: #ffffff;
    color: #000000;
}

#network {
    background-color: #ffffff;
    font-size: 16px;
    color: #000000;
    border-radius: 15px;
    padding: 2px 10px 0px 10px;
    margin: 5px 15px 5px 0px;
    opacity:0.8;
}

#network.ethernet {
    background-color: #ffffff;
    color: #000000;
}

#network.wifi {
    background-color: #ffffff;
    color: #000000;
}

#bluetooth, #bluetooth.on, #bluetooth.connected {
    background-color: #ffffff;
    font-size: 16px;
    color: #000000;
    border-radius: 15px;
    padding: 2px 10px 0px 10px;
    margin: 5px 15px 5px 0px;
    opacity:0.8;
}

#bluetooth.off {
    background-color: transparent;
    padding: 0px;
    margin: 0px;
}

#battery {
    background-color: #ffffff;
    font-size: 16px;
    color: #000000;
    border-radius: 15px;
    padding: 2px 15px 0px 10px;
    margin: 5px 15px 5px 0px;
    opacity:0.8;
}

#battery.charging, #battery.plugged {
    color: #000000;
    background-color: #ffffff;
}

@keyframes blink {
    to {
        background-color: #ffffff;
        color: #000000;
    }
}

#battery.critical:not(.charging) {
    background-color: #f53c3c;
    color: #000000;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

#tray {
    padding: 0px 15px 0px 0px;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
}
    '';
  };
}
