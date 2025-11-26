{ config, lib, pkgs, ... }:

let
  unstable = import <nixos-unstable> {
    config = {
      allowUnfree = true;
    }; # If needed
  };
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.frivermen = {
    isNormalUser = true;
    home = "/home/frivermen";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.hyprland}/bin/Hyprland";
        user = "frivermen";
      };
      default_session = initial_session;
    };
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    settings.PermitRootLogin = "yes";
  };

  networking.networkmanager.enable = true;

  programs.hyprland = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    # Stable packages
    dunst
    firefox
    foot
    git
    helix
    plocate
    waybar
    wget
    wofi
    nnn
    libnotify
    vanilla-dmz
    ayugram-desktop
    hyprshot
    # Unstable packages
#    unstable.nil # nix lsp for helix
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.roboto-mono
    paratype-pt-serif
    paratype-pt-sans
  ];

  system.stateVersion = "25.05"; # Did you read the comment?

}
