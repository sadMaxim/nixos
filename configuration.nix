# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Moonlight at 1440p60/50 Mbit/s over WireGuard needs enough UDP buffering to
  # survive short Wi-Fi and scheduler stalls. The default 212 KiB caused tens
  # of thousands of UdpRcvbufErrors and consecutive unrecoverable frames.
  boot.kernel.sysctl = {
    "net.core.rmem_default" = 1048576;
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_default" = 1048576;
    "net.core.wmem_max" = 16777216;
    "net.core.netdev_max_backlog" = 5000;
  };

  boot.initrd.luks.devices."luks-67f943c7-079c-472e-9335-0d315c671c40".device = "/dev/disk/by-uuid/67f943c7-079c-472e-9335-0d315c671c40";
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager = {
    enable = true;
    # Prevent periodic Wi-Fi power-save stalls from dropping Moonlight UDP frames.
    wifi.powersave = false;
  };


  # Set your time zone.
  time.timeZone = "Europe/Stockholm";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sv_SE.UTF-8";
    LC_IDENTIFICATION = "sv_SE.UTF-8";
    LC_MEASUREMENT = "sv_SE.UTF-8";
    LC_MONETARY = "sv_SE.UTF-8";
    LC_NAME = "sv_SE.UTF-8";
    LC_NUMERIC = "sv_SE.UTF-8";
    LC_PAPER = "sv_SE.UTF-8";
    LC_TELEPHONE = "sv_SE.UTF-8";
    LC_TIME = "sv_SE.UTF-8";
  };

  # Disable the X11 windowing system; we'll run Wayland-only Hyprland instead.
  services.xserver.enable = false;

  # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb = {
  #   layout = "us";
  #   variant = "";
  # };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Do not apply ModelBouncingKeys globally: it interferes with rapid A/D
  # counter-strafing in streamed games. If keyboard chatter needs filtering,
  # scope a quirk to the specific faulty keyboard rather than all keyboards.

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.maxim = {
    isNormalUser = true;
    description = "maxim";
    extraGroups = [ "networkmanager" "wheel" "postgres" "adbusers" "video" "docker" ];
    packages = with pkgs; [
    #  thunderbird
    pavucontrol
    ];
  };

  # gpu-screen-recorder: promptless full-screen recording via the gsr-kms-server setcap wrapper.
  # See modules/hyprland.nix for the replay daemon, hotkeys, and the gsr-toggle/gsr-save-replay scripts.
  programs.gpu-screen-recorder.enable = true;

  # Steam.  `programs.steam` (rather than `pkgs.steam` in home.packages) sets
  # up the `steam` group and pulls in the 32-bit Vulkan/OpenGL drivers needed
  # by most native Linux games.  `allowUnfree = true` is already set above,
  # which is required.
  #
  # After `sudo nixos-rebuild switch`, add yourself to the steam group so
  # games can access your home directory's game prefixes without permission
  # errors: `sudo usermod -aG steam $USER`, then log out and back in.
  programs.steam = {
    enable = true;
    # Open the firewall ports Steam Remote Play needs if you ever stream
    # from another machine.  Comment out if you don't use Remote Play.
    remotePlay.openFirewall = true;
  };

  # Install firefox.
  programs.firefox.enable = true;
  # mobile connect 
  # programs.kdeconnect.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Overlay to add latest runpodctl (pre-built binary)
  nixpkgs.overlays = [
    (final: prev: {
      runpodctl = final.stdenv.mkDerivation {
        pname = "runpodctl";
        version = "2.2.0";
        src = final.fetchurl {
          url = "https://github.com/runpod/runpodctl/releases/download/v2.2.0/runpodctl-linux-amd64.tar.gz";
          sha256 = "0mq819kw4y1f6ah0r46jsi0rl11r93d0blfaalx05g1r045mplqi";
        };
        sourceRoot = ".";
        installPhase = ''
          install -Dm755 runpodctl $out/bin/runpodctl
        '';
        meta = with final.lib; {
          description = "CLI tool to manage Runpod resources";
          homepage = "https://github.com/Run-Pod/runpodctl";
          license = final.lib.licenses.asl20;
          platforms = final.lib.platforms.linux;
        };
      };
    })
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    lm_sensors
    libva-utils
    htop
    gocryptfs
    pamixer
    openssl
    gcc
    android-tools
    simple-mtpfs
    gh
    docker-buildx
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable Docker.
  virtualisation.docker.enable = true;

  # Xray tunnel to vdsina — replaces `wg-vdsina` WireGuard profile (DPId).
  # Config (with Reality keys) lives in /home/maxim/.config/xray/config.json
  # which is gitignored. This repo contains ONLY the file path, never secrets.
  #
  # Use the locally-built xray 26.3.27 binary instead of pkgs.xray (which
  # is xray-core 25.10.15 — its TUN config parser refuses any inbound
  # without a listen+port pair, so the TUN inbound fails with
  # 'Listen on AnyIP but no Port(s) set in InboundDetour').
  services.xray = {
    enable = true;
    package = pkgs.runCommandLocal "xray-26.3.27-local" { } ''
      mkdir -p $out/bin
      cp ${/home/maxim/.local/share/xray-test/xray} $out/bin/xray
      chmod +x $out/bin/xray
    '';
    settingsFile = "/home/maxim/.config/xray/config.json";
  };

  # Tailscale disabled; the gaming VM uses a dedicated WireGuard tunnel.
  services.tailscale.enable = false;

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

  programs.hyprland = {
    enable = true;
    # Set to true if you need X11 apps via Xwayland.
    xwayland.enable = false;
  };
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
      user = "greeter";
    };
  };
  hardware.graphics = {
    enable = true;
    # Kaby Lake Iris Plus 640: hardware H.264/HEVC decoding for Moonlight.
    extraPackages = with pkgs; [ intel-media-driver ];
  };
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  services.udisks2.enable = true;
  services.gvfs.enable = true;  # good for Dolphin/Thunar/PCManFM, etc.
  # display
  services.ddccontrol.enable = true;
  ### database postgres (local-only)
  services.postgresql = {
    enable = true;
    enableTCPIP = false;
    ensureDatabases = [ "maxim" ];
    ensureUsers = [{ name = "maxim"; ensureDBOwnership = true; }];
  };

  systemd.services.fix-postgresql = {
    wantedBy = [ "multi-user.target" ];
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];

    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
    };

    path = [ pkgs.postgresql ];

    script = ''
      psql -d maxim -c "ALTER SCHEMA public OWNER TO maxim;"
      psql -d maxim -c "GRANT USAGE, CREATE ON SCHEMA public TO maxim;"
    '';
  };

  ## bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Shows battery charge of connected devices on supported
        # Bluetooth adapters. Defaults to 'false'.
        Experimental = true;
        # When enabled other devices can connect faster to us, however
        # the tradeoff is increased power consumption. Defaults to
        # 'false'.
        FastConnectable = true;
      };
      Policy = {
        # Enable all controllers when they are found. This includes
        # adapters present on start as well as adapters that are plugged
        # in later on. Defaults to 'true'.
        AutoEnable = true;
      };
    };
  };
  services.blueman.enable = true;



  # Fonts configuration
  fonts.packages = with pkgs; [
     nerd-fonts.jetbrains-mono
     nerd-fonts.fira-code
  ];



  powerManagement.resumeCommands = ''
  # Make sure NetworkManager restarts each time we resume
    systemctl restart NetworkManager.service
  '';


  nix = {
    settings = {
      auto-optimise-store = true;
      trusted-users = [ "root" "maxim" ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
        "https://cache.numtide.com"
        # "https://nix-gaming.cachix.org"
        "https://hyprland.cachix.org"
        # "https://ghostty.cachix.org"
        # "https://vicinae.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        # "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        # "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
        # "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      ];
    };
  };
}
