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
    ./modules/frivermen-home.nix
    ./modules/root-home.nix
    ./beeper-alarm/beeper-services.nix
    (import "${home-manager}/nixos")
  ];

  nixpkgs.config.allowUnfree = true;

  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [
    "nct6775"
    "pcspkr"
  ];


  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1"; # or "nodev" for efi only
  boot.loader.grub.gfxmodeBios = "text";

  networking.hostName = "x99-frivermen";
  i18n.defaultLocale = "ru_RU.UTF-8";
  time.timeZone = "Asia/Yekaterinburg";

  home-manager.useGlobalPkgs = true;
  home-manager.backupFileExtension = "backup";

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    # settings.PermitRootLogin = "yes";
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  hardware.bluetooth.settings.General.ControllerMode = "bredr";
  services.pipewire.wireplumber.extraConfig."10-bluez" = {
    "monitor.bluez.properties" = {
      "bluez5.roles" = [ "a2dp_sink" "a2dp_source" ];
    };
  };
  services.pipewire.wireplumber.extraConfig."11-bluetooth-policy" = {
    "wireplumber.settings" = {
      "bluetooth.autoswitch-to-headset-profile" = false;
    };
  };

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

  # vpn
  programs.amnezia-vpn.enable = true;
  programs.amnezia-vpn.package = unstable.amnezia-vpn;

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

  # adb
  programs.adb.enable = true;

  # virtualbox
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
    exfat
    imagemagick
    feh
    gnumeric
    beep
    anydesk
    usbutils
    vdhcoapp
    # rustdesk
    qbittorrent
    texliveFull
    gnumake
    pandoc
    socat
    moserial
    yt-dlp
    inkscape
    gimp
    zenity
    (python3.withPackages (python-pkgs: with python-pkgs; [
      tkinter
    ]))
    # Unstable packages
    unstable.nil # nix lsp for helix
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.roboto-mono
    paratype-pt-serif
    paratype-pt-sans
  ];

  system.stateVersion = "25.05"; # Did you read the comment?

  nixpkgs.overlays = [(
    final: prev: {
      kmod-blacklist-ubuntu = prev.kmod-blacklist-ubuntu.overrideAttrs (old: {
        patches = [
          ./beeper-alarm/Dont-blacklist-pcspkr.patch
        ];
      });
    }
  )];
}
