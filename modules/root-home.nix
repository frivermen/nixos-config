{
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
}
