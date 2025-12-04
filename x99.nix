{ config, lib, pkgs, ... }:
let
  # sudo nix-channel --add https://nixos.org/channels/nixpkgs-unstable unstable
  # sudo nix-channel --update
  unstable = import <unstable> { config = { allowUnfree = true; }; };
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz";
in
{
  imports = [
    /etc/nixos/hardware-configuration.nix
    (import "${home-manager}/nixos")
  ];

  nixpkgs.config.allowUnfree = true;

  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [
    "nct6775"
  ];


  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1"; # or "nodev" for efi only
  boot.loader.grub.gfxmodeBios = "text";

  networking.hostName = "x99-frivermen";
  i18n.defaultLocale = "ru_RU.UTF-8";
  time.timeZone = "Asia/Yekaterinburg";

  users.users.frivermen = {
    isNormalUser = true;
    home = "/home/frivermen";
    extraGroups = [
      "wheel"
      "networkmanager"
      "vboxusers"
    ];
  };

  home-manager.useGlobalPkgs = true;
  home-manager.backupFileExtension = "backup";
  home-manager.users.frivermen = { pkgs, ... }: {
    programs.bash = {
      enable = true;
      initExtra = ''
        GREEN='\[\e[01;32m\]'
        RED='\[\e[01;31m\]'
        RESET='\[\e[00m\]'
        # if root ? set red : set green
        (( EUID == 0 )) && MAIN=$RED || MAIN=$GREEN
        PS1='[\t] '$MAIN'[\u] '$RESET'in '$MAIN'[\w]\n \$ '$RESET
        PATH="$PATH:~/bin"

        export PROMPT_COMMAND="''${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r;"
        export EDITOR=hx
        export VISUAL=hx

      n ()
      {
          # Block nesting of nnn in subshells
          [ "''${NNNLVL:-0}" -eq 0 ] || {
              exit
          }
          [ -n "$NNNLVL" ] && PS1="N$NNNLVL $PS1"

          # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
          # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
          # see. To cd on quit only on ^G, remove the "export" and make sure not to
          # use a custom path, i.e. set NNN_TMPFILE *exactly* as follows:
          #      NNN_TMPFILE="''${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
          export NNN_TMPFILE="''${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
          export NNN_TRASH=1

          # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
          # stty start undef
          # stty stop undef
          # stty lwrap undef
          # stty lnext undef

          # The command builtin allows one to alias nnn to n, if desired, without
          # making an infinitely recursive alias
          # command nnn -e -x -d -r "$@"
          command nnn -e -x -d "$@"

          [ ! -f "$NNN_TMPFILE" ] || {
              . "$NNN_TMPFILE"
              rm -f -- "$NNN_TMPFILE" > /dev/null
          }
      }

      lc() {
          if [ -z "$2" ]; then
              lua -e "print(string.format('%.2f', $1))"  # по умолчанию 2 знака
          else
              lua -e "print(string.format('%.''${2}f', $1))"  # кастомный scale
          fi
      }

      u() { 
          local mount_dir="/run/media/frivermen"
          local drives=()
          local choice selected i
    
          # Check if mount directory exists
          [[ -d "$mount_dir" ]] || { echo "Mount directory not found"; return 1; }
    
          # Get list of flash drives
          for dir in "$mount_dir"/*; do
              [[ -d "$dir" ]] && drives+=("$dir")
          done
    
          # Check if any drives found
          if [[ ''${#drives[@]} -eq 0 ]]; then
              echo "No flash drives connected"
              return 0
          fi
    
          # Display list
          echo "Connected flash drives:"
          for i in "''${!drives[@]}"; do
              echo "''$((i+1)). ''${drives[i]##*/}"
          done
    
          # Get user choice
          read -p "Select drive to unmount (1-''${#drives[@]}, or 0 to cancel): " choice
    
          # Validate input
          if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -gt ''${#drives[@]} ]]; then
              echo "Invalid selection"
              return 1
          fi
    
          [[ "$choice" -eq 0 ]] && { echo "Cancelled"; return 0; }
    
          # Unmount selected drive
          selected="''${drives[$((choice-1))]}"
          echo "Unmounting $selected..."
          if umount "$selected"; then
              echo "Successfully unmounted"
              rmdir "$selected" 2>/dev/null && echo "Directory removed"
          else
              echo "Unmount failed"
              return 1
          fi
      }
      '';
      shellAliases = {
        mount = "udisksctl mount -b";
        bs = "cat ~/.bash_history | grep";
        feh = "feh -.Z $@";
        nsearch = "nix --extra-experimental-features \"nix-command flakes\" search nixpkgs";
        nedit = "sudo hx /etc/nixos/configuration.nix";
        nswitch = "sudo nixos-rebuild switch";
      };
      historyFileSize = 9000;
      historySize = 9000;
      profileExtra = ''
        if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
          exec Hyprland
        fi
      '';
    };

    programs.zathura = {
      enable = true;
      options = {
        notification-error-bg     = "rgba(251,241,199,1)"  ;# bg
        notification-error-fg     = "rgba(157,0,6,1)"      ;# bright:red
        notification-warning-bg   = "rgba(251,241,199,1)"  ;# bg
        notification-warning-fg   = "rgba(181,118,20,1)"   ;# bright:yellow
        notification-bg           = "rgba(251,241,199,1)"  ;# bg
        notification-fg           = "rgba(121,116,14,1)"   ;# bright:green

        completion-bg             = "rgba(213,196,161,1)"  ;# bg2
        completion-fg             = "rgba(60,56,54,1)"     ;# fg
        completion-group-bg       = "rgba(235,219,178,1)"  ;# bg1
        completion-group-fg       = "rgba(146,131,116,1)"  ;# gray
        completion-highlight-bg   = "rgba(7,102,120,1)"    ;# bright:blue
        completion-highlight-fg   = "rgba(213,196,161,1)"  ;# bg2

# Define the color in index mode
        index-bg                  = "rgba(213,196,161,1)"  ;# bg2
        index-fg                  = "rgba(60,56,54,1)"     ;# fg
        index-active-bg           = "rgba(7,102,120,1)"    ;# bright:blue
        index-active-fg           = "rgba(213,196,161,1)"  ;# bg2

        inputbar-bg               = "rgba(251,241,199,1)"  ;# bg
        inputbar-fg               = "rgba(60,56,54,1)"     ;# fg

        statusbar-bg              = "rgba(213,196,161,1)"  ;# bg2
        statusbar-fg              = "rgba(60,56,54,1)"     ;# fg

        highlight-color           = "rgba(181,118,20,0.5)" ;# bright:yellow
        highlight-active-color    = "rgba(175,58,3,0.5)"   ;# bright:orange

        default-bg                = "rgba(251,241,199,1)"  ;# bg
        default-fg                = "rgba(60,56,54,1)"     ;# fg
        render-loading            = true;
        render-loading-bg         = "rgba(251,241,199,1)"  ;# bg
        render-loading-fg         = "rgba(60,56,54,1)"     ;# fg

# Recolor book content's color
        recolor-lightcolor        = "rgba(251,241,199,1)"  ;# bg
        recolor-darkcolor         = "rgba(60,56,54,1)"     ;# fg
        recolor                   = "true";
        recolor-keephue           = "true"                 ;# keep original color
      };
    };
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "Danil Safichuk";
          email = "frivermen@mail.ru";
        };
      };
    };

    gtk = {
      enable = true;
      theme.name = "Breeze";
      iconTheme.name = "breeze";
      cursorTheme.name = "Vanilla-DMZ-AA";
      cursorTheme.size = 24;
    };

    services.dunst = {
      enable = true;
      settings.global = {
        monitor = "HDMI-A-1";
        separator_color = "frame";
        corner_radius = 10;
        background = "#3c3836";
        foreground = "#fbf1c7";
        frame_color = "#fe8019";
      };
    };

    services.hyprpaper = {
      enable = true;
      settings = {
        preload = [ "/etc/nixos/nixos-config/Morskie Oko.jpg" ];
        wallpaper = [ ", /etc/nixos/nixos-config/Morskie Oko.jpg" ];
      };
    };

    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        debug.disable_logs = false;
        "$leftMonitor" = "HDMI-A-1";
        "$rightMonitor" = "DVI-I-1";
        # port DP-1, resolution 1920x1080, position 0x0, scale 1
        monitor = [
          "$leftMonitor, 2560x1440@59.95, 0x0, auto"
          "$rightMonitor, 1920x1080@60, 2560x220, auto"
        ];
        workspace = [
          "name:1, monitor:$leftMonitor"
          "name:2, monitor:$leftMonitor"
          "name:3, monitor:$leftMonitor"
          "name:4, monitor:$leftMonitor"
          "name:5, monitor:$leftMonitor"
          "name:6, monitor:$leftMonitor"
        ];
        "$terminal" = "foot";
        "$fileManager" = "$terminal nnn";
        "$menu" = "wofi -i --show drun";
        "$screenshot" = "hyprshot -m region --clipboard-only";
        "exec-once" = [
          "hyprctl dispatch workspace 1"
          # "waybar"
          # "hyprpaper"
          # "dunst"
          "firefox"
          "AyuGram"
          "ciadpi -o1 -s4 -s6 -a1"
          "nm-applet"
          "blueman-applet"
          "udiskie --tray -f 'foot nnn'"
          "yandex-disk start"
        ];
        env = [
          "XCURSOR_THEME,DMZ-Black"
          "XCURSOR_SIZE,24"
        ];
        general = {
          border_size = 3;
          gaps_in = 5;
          gaps_out = 10;
          "col.inactive_border" = "rgba(e6dcb2AA)";
          "col.active_border" = "rgba(fe8019AA)";
          layout = "dwindle";
        };
        decoration = {
          rounding = 10;
          rounding_power = 2;
          active_opacity = 1.0;
          inactive_opacity = 0.95;
          blur.enabled = true;
          shadow.enabled = true;
        };
        animations.enabled = false;
        input = {
          kb_layout = "us,ru";
          kb_options = "grp:win_space_toggle, ctrl:nocaps";
          sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
          follow_mouse = 1;
          touchpad.tap_button_map = "lmr";
        };
        misc = {
          disable_hyprland_logo = true;
          force_default_wallpaper = 0;
        };
        cursor = {
          no_hardware_cursors = 1;
        };
        "$mainMod" = "SUPER";
        bind = [
          # some actions
          "$mainMod SHIFT, return, exec, $terminal"
          "$mainMod, E, exec, $fileManager"
          "$mainMod, P, exec, $menu"
          "$mainMod SHIFT, S, exec, $screenshot"
          "$mainMod SHIFT, C, killactive,"
          "$mainMod SHIFT, Q, exit,"
          "$mainMod SHIFT, B, exec, pkill waybar && hyprctl dispatch exec waybar"
          "$mainMod, V, exec, [float; size 1000 750] pavucontrol"
          "$mainMod, A, exec, if mountpoint -q ~/mtp; then umount ~/mtp && notify-send 'MTP unmounted!'; else  mkdir -p ~/mtp && aft-mtp-mount ~/mtp && notify-send 'MTP mounted!'; fi"

          # modes
          "$mainMod, F, togglefloating,"
          "$mainMod, T, pseudo, # dwindle"
          "$mainMod, M, fullscreen, 1"
          "$mainMod SHIFT, M, fullscreen, 0"

          # window focus
          "$mainMod, h, movefocus, l"
          "$mainMod, j, movefocus, d"
          "$mainMod, k, movefocus, u"
          "$mainMod, l, movefocus, r"

          # switch to tag
          "$mainMod, TAB, workspace, previous"
          "$mainMod, 1, workspace, 1"
          "$mainMod, 2, workspace, 2"
          "$mainMod, 3, workspace, 3"
          "$mainMod, 4, workspace, 4"
          "$mainMod, 5, workspace, 5"
          "$mainMod, 6, workspace, 6"
          "$mainMod, 7, workspace, 7"
          "$mainMod, 8, workspace, 8"
          "$mainMod, 9, workspace, 9"
          "$mainMod, 0, workspace, 10"

          # send to tag
          "$mainMod SHIFT, 1, movetoworkspace, 1"
          "$mainMod SHIFT, 2, movetoworkspace, 2"
          "$mainMod SHIFT, 3, movetoworkspace, 3"
          "$mainMod SHIFT, 4, movetoworkspace, 4"
          "$mainMod SHIFT, 5, movetoworkspace, 5"
          "$mainMod SHIFT, 6, movetoworkspace, 6"
          "$mainMod SHIFT, 7, movetoworkspace, 7"
          "$mainMod SHIFT, 8, movetoworkspace, 8"
          "$mainMod SHIFT, 9, movetoworkspace, 9"
          "$mainMod SHIFT, 0, movetoworkspace, 10"

          # send to monitor
          "$mainMod SHIFT, comma, movecurrentworkspacetomonitor, l"
          "$mainMod SHIFT, period, movecurrentworkspacetomonitor, r"
        ];
        bindm = [
          # Move/resize windows with mainMod + LMB/RMB and dragging
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];
        bindel = [
          # Laptop multimedia keys for volume and LCD brightness
          ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
          ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
          ",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
        ];
        windowrulev2 = [
          "suppressevent maximize, class:.*"
          "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
          "workspace 2 silent, class:firefox"
          "workspace 3 silent, class:^(com.ayugram.desktop|com.telegram.desktop)$"
          "workspace 4, class:^(kompas.exe)$"
          "noblur, class:^(kompas.exe)$"
          "opaque, title:^(КОМПАС-3D.*)$ "
          "tile, title:^(КОМПАС-3D.*)$"
          "size 800 600,class:^(kompas.exe)$,title:^(RoamingWindow)$"
          "float, class:^(wlvncc)$"
        ];
      };
    };

    programs.waybar = {
      enable = true;
      systemd.enable = true;
      style = ''
        * {
            font-family: RobotoMono Nerd Font;
            font-size: 14px; 
            font-weight: bold;
            min-height: 0;
            border-radius: 10px;
            box-shadow: none;
        }

        menu {
            border-radius: 10px;
            color: #3c3836;
            background: #fbf1c7;
        }

        menuitem {
            border-radius: 10px;
        }

        #custom-button {
            color: #3c3836;
            background: #fbf1c7;
            margin-right: 5px;
        }

        window#waybar {
            background: transparent;
            /* background: rgba(0xfb,0xf1,0xc7,0.2); */
        }

        window#waybar.hidden {
            opacity: 0.2;
        }

        #workspaces {
            /* margin-left: 5px; */
            margin-right: 5px;
            border-radius: 10px;
            transition: none;
            background: #fbf1c7;
        }

        #workspaces button {
            color: #928374;
            transition: none;
            background: transparent;
            padding-right: 10px;
            padding-left: 10px;
        }

        /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
        #workspaces button:hover {
            transition: none;
            box-shadow: inherit;
            text-shadow: inherit;
            border-radius: inherit;
            color: #3c3836;
            background: #f9f5d7;
        }

        #workspaces button.urgent {
            color: #fbf1c7;
            background: #fe8019;
            border-radius: inherit;
        }

        #workspaces button.active {
            color: #fe8019;
            background: #fbf1c7;
            border-radius: inherit;
        }

        #language,
        #clock,
        tooltip,
        #temperature,
        #memory,
        #pulseaudio {
            border-radius: 10px;
            margin-right: 5px;
            margin-left: 5px;
            transition: none;
            color: #3c3836;
            background: #fbf1c7;
        }

        #tray {
            border-radius: 10px 10px 10px 10px;
            margin-left: 5px;
            transition: none;
            color: #3c3836;
            background: #fbf1c7;
            padding-right: 10px;
            padding-left: 10px;
        }
      '';
      settings = {
        mainBar = {
          "position" = "top";
          "layer" = "top";
          "margin" = "10 10 0 10";
          "modules-left" = [
            "hyprland/workspaces"
            "custom/button"
          ];
          "modules-center" = [
            "clock"
          ];
          "modules-right" = [
            "temperature"
            "memory"
            "pulseaudio"
            "hyprland/language"
            "tray"
          ];
          "hyprland/workspaces" = {
            "disable-scroll" = true;
          };
          "custom/button" = {
            "format"  = "+";
            "tooltip" = true;
            "tooltip-format" = "left or right click";
            "min-length" = 3;
            "on-click" = "hyprctl dispatch workspace empty";
            "on-click-right" = "wofi --show drun -i -l 1 -x 10 -y 10";
          };
          "clock" = {
            "format" = "{:%d.%m.%Y %H:%M}";
            "min-length" = 18;
            "tooltip-format" = "{calendar}";
            "on-scroll"      = 1;
            "calendar" = {
              "mode"           = "year";
              "mode-mon-col"   = 3;
            };
            "actions" =  {
              "on-click-left" = "calendar";
              "on-scroll-up" = "shift_up";
              "on-scroll-down" = "shift_down";
            };
          };
          "temperature" = {
            "thermal-zone" = 0;
            "hwmon-path" = "/sys/class/hwmon/hwmon3/temp1_input";
            "format" = "{temperatureC}°C";
            "tooltip-format" = "CPU temp";
            "min-length" = 6;
          };
          "memory" = {
            "interval" = 10;
            "format" = "R{}%";
            "min-length" = 6;
          };
          "pulseaudio" = {
            "format" = "V{volume}%";
            "format-bluetooth" = "  V{volume}% ";
            "format-muted" = "MUTE";
            "min-length" = 7;
            "on-click" = "pavucontrol";
            "tooltip-format" = "scroll or click";
          };
          "hyprland/language" = {
            "format-en" = "EN";
            "format-ru" = "RU";
            "min-length" = 5;
            "on-click" = "hyprctl switchxkblayout current prev";
            "tooltip-format" = "win + space";
          };
          "tray" = {
            "icon-size" = 18;
            "spacing" = 5;
          };
        };
      };
    };

    programs.wofi = {
      enable = true;
      style = ''
        window,
        #input {
          color: #3c3836;
          background: #fbf1c7;
        }
      '';
    };

    xdg.userDirs = {
      enable = true;
      desktop = "$HOME/desktop";
      documents="$HOME/documents";
      download = "$HOME/downloads";
      music="$HOME/.music";
      pictures="$HOME/pictures";
      publicShare="$HOME/.public";
      templates="$HOME/.templates";
      videos="$HOME/.videos";
    };

    programs.foot = {
      enable = true;
      settings = {
        main = {
          font = "RobotoMono Nerd Font Mono:size=12";
        };
        colors = {
          background = "fbf1c7";
          foreground = "3c3836";
          regular0 = "fbf1c7";
          regular1 = "cc241d";
          regular2 = "98971a";
          regular3 = "d79921";
          regular4 = "458588";
          regular5 = "b16286";
          regular6 = "689d6a";
          regular7 = "7c6f64";
          bright0 = "928374";
          bright1 = "9d0006";
          bright2 = "79740e";
          bright3 = "b57614";
          bright4 = "076678";
          bright5 = "8f3f71";
          bright6 = "427b58";
          bright7 = "3c3836";
        };
      };
    };

    programs.helix = {
      enable = true;
      defaultEditor = true;
      languages.language = [
        { name = "python"; indent = { tab-width = 2; unit = "  "; }; }
      ];
      settings = {
        theme = "gruvbox_light";
        editor = {
          line-number = "relative";
          mouse = false;
          middle-click-paste = true;
          cursorline = true;
          color-modes = true;
          scrolloff = 19;
          rulers = [120];
          bufferline = "multiple";
          clipboard-provider = "wayland";
          statusline = {
            left = ["mode" "spinner" "read-only-indicator""file-encoding"];
            center = ["file-name" "file-modification-indicator"];
            right = ["diagnostics" "selections" "position" "position-percentage" "total-line-numbers"];
            separator = "|";
          };
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
          file-picker.hidden = false;
          indent-guides.render = true;
          whitespace.render = {
            space = "all";
            tab = "all";
          };
        };
        keys.normal = {
          "C-l" = [":write" ":run-shell-command make | tee ~/.myfifo"];
        };
        keys.insert = {
          "C-[" = "normal_mode";
          "S-ret" = "open_below";
        };
      };
    };

    home.stateVersion = "25.11";
  };

  home-manager.users.root = { pkgs, ... }: {
    programs.bash = {
      enable = true;
      initExtra = ''
        GREEN='\[\e[01;32m\]'
        RED='\[\e[01;31m\]'
        RESET='\[\e[00m\]'
        # if root ? set red : set green
        (( EUID == 0 )) && MAIN=$RED || MAIN=$GREEN
        PS1='[\t] '$MAIN'[\u] '$RESET'in '$MAIN'[\w]\n \$ '$RESET
      '';
      shellAliases = {
        bs = "cat ~/.bash_history | grep";
        nsearch = "nix --extra-experimental-features \"nix-command flakes\" search nixpkgs";
        nedit = "sudo hx /etc/nixos/configuration.nix";
        nswitch = "sudo nixos-rebuild switch";
      };
      historyFileSize = 9000;
      historySize = 9000;
    };

    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "Danil Safichuk";
          email = "frivermen@mail.ru";
        };
      };
    };

    programs.helix = {
      enable = true;
      defaultEditor = true;
      settings = {
        theme = "gruvbox";
        editor = {
          line-number = "relative";
          mouse = false;
          middle-click-paste = true;
          cursorline = true;
          color-modes = true;
          scrolloff = 19;
          rulers = [120];
          bufferline = "multiple";
          clipboard-provider = "wayland";
          statusline = {
            left = ["mode" "spinner" "read-only-indicator""file-encoding"];
            center = ["file-name" "file-modification-indicator"];
            right = ["diagnostics" "selections" "position" "position-percentage" "total-line-numbers"];
            separator = "|";
          };
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
          file-picker.hidden = false;
          indent-guides.render = true;
          whitespace.render = {
            space = "all";
            tab = "all";
          };
        };
        keys.normal = {
          "C-l" = [":write" ":run-shell-command make | tee ~/.myfifo"];
        };
        keys.insert = {
          "C-[" = "normal_mode";
          "S-ret" = "open_below";
        };
      };
    };

    home.stateVersion = "25.11";
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    # settings.PermitRootLogin = "yes";
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.services.firewall.enable = false;

  hardware.fancontrol.enable = true;
  hardware.fancontrol.config = ''
    INTERVAL=10
    DEVPATH=hwmon3=devices/platform/coretemp.0 hwmon2=devices/platform/nct6775.2592
    DEVNAME=hwmon3=coretemp hwmon2=nct6779
    FCTEMPS=hwmon2/pwm1=hwmon3/temp1_input hwmon2/pwm2=hwmon3/temp1_input
    FCFANS=hwmon2/pwm1=hwmon2/fan2_input hwmon2/pwm2=hwmon2/fan2_input
    MINTEMP=hwmon2/pwm1=45 hwmon2/pwm2=40
    MAXTEMP=hwmon2/pwm1=70 hwmon2/pwm2=70
    MINSTART=hwmon2/pwm1=150 hwmon2/pwm2=150
    MINSTOP=hwmon2/pwm1=100 hwmon2/pwm2=0
  '';

  # usb automount
  services.udisks2.enable = true;

  # sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  
  # wayland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.sessionVariables = {
    # fix invisible cursor
    WLR_NO_HARDWARE_CURSORS = "1";
    # to apps use wayland
    NIXOS_OZONE_WL = "1";
  };

  # video drivers
  hardware = {
    graphics.enable = true;
    amdgpu.legacySupport.enable = true;
  };

  # amd overclocking and etc.
  services.lact.enable = true;

  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;
  users.extraGroups.vboxusers.members = [ "user-with-access-to-virtualbox" ];

  environment.systemPackages = with pkgs; [
    # Stable packages
    android-file-transfer # android mount
    ayugram-desktop # telegram client
    telegram-desktop # telegram client
    byedpi # dpi proxy
    dunst # notifications
    firefox 
    foot # terminal emulator
    git
    helix # editor
    htop
    hyprpaper # wallpaper setter
    hyprshot # sceenshoter
    kdePackages.breeze
    kdePackages.breeze-gtk
    kdePackages.breeze-icons
    killall
    libnotify
    lm_sensors
    networkmanagerapplet
    nnn # cli file explorer
    nwg-look # gtk setup
    mpv # video player
    p7zip
    pavucontrol
    plocate # search files
    udiskie # automount usb
    vanilla-dmz # cursor theme
    waybar 
    wget
    wlvncc # vnc client
    wineWowPackages.unstableFull # wine
    winetricks
    wofi # apps launcher
    wl-clipboard
    trash-cli # trash for nnn
    zapret
    mesa-demos
    yandex-disk
    libreoffice-fresh
    lua
    hunspell
    hunspellDicts.ru_RU
    hunspellDicts.en_US
    hunspellDicts.en_GB-ize
    hyphenDicts.ru_RU
    hyphenDicts.en_US
    tree
    progress
    zathura
    # Unstable packages
    unstable.nil # nix lsp for helix
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.roboto-mono
    paratype-pt-serif
    paratype-pt-sans
  ];

  system.stateVersion = "25.05"; # Did you read the comment?

}
