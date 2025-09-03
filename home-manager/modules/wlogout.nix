{ pkgs, ... }:
{
  programs.wlogout = {
    enable = true;
    layout = [
      {
        label = "lock";
        action = "/etc/nixos/scripts/power.sh lock";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "logout";
        action = "/etc/nixos/scripts/power.sh exit";
        text = "Log Out";
        keybind = "e";
      }
      {
        label = "suspend";
        action = "/etc/nixos/scripts/power.sh suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "reboot";
        action = "/etc/nixos/scripts/power.sh reboot";
        text = "Restart";
        keybind = "r";
      }
      {
        label = "shutdown";
        action = "/etc/nixos/scripts/power.sh shutdown";
        text = "Power Off";
        keybind = "s";
      }
    ];
    style = ''
    * {
        font-family: "NotoSans Nerd Font", Roboto, Helvetica, Arial, sans-serif;
        background-image: none;
        transition: 20ms;
        box-shadow: none;
    }

    window {
        background-size: cover;
        background-color: #1e1e2e;
        font-size: 16pt;
        color: #ffffff;
    }

    button {
        background-repeat: no-repeat;
        background-position: center;
        background-size: 20%;
        background-color: rgba(200, 220, 255, 0);
        color: #cdd6f4;
        animation: gradient_f 20s ease-in infinite;
        border-radius: 80px;
        border: 0px;
        transition: all 0.3s cubic-bezier(.55, 0.0, .28, 1.682), box-shadow 0.2s ease-in-out, background-color 0.2s ease-in-out;
    }

    button:focus {
        background-size: 22%;
        border: 0px;
    }

    button:hover {
        background-color: #45475a;
        opacity: 0.8;
        color: #cdd6f4;
        background-size: 30%;
        margin: 30px;
        border-radius: 80px;
        box-shadow: 0 0 50px #000000;
    }

    button span {
        font-size: 1.2em;
    }

    #lock {
        margin: 10px;
        border-radius: 20px;
        background-image: image(url("/etc/nixos/icons/lock.png"));
    }

    #logout {
        margin: 10px;
        border-radius: 20px;
        background-image: image(url("/etc/nixos/icons/logout.png"));
    }

    #suspend {
        margin: 10px;
        border-radius: 20px;
        background-image: image(url("/etc/nixos/icons/suspend.png"));
    }

    #hibernate {
        margin: 10px;
        border-radius: 20px;
        background-image: image(url("/etc/nixos/icons/hibernate.png"));
    }

    #shutdown {
        margin: 10px;
        border-radius: 20px;
        background-image: image(url("/etc/nixos/icons/shutdown.png"));
    }

    #reboot {
        margin: 10px;
        border-radius: 20px;
        background-image: image(url("/etc/nixos/icons/reboot.png"));
    }
    '';
  };
}

