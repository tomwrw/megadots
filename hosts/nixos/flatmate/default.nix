{
  # Set the host-specific hostname here.
  networking = {
    hostName = "flatmate";
    domain = "home.arpa";
  };
  # Set the hosts system state version.
  # This is the NixOS release from which the default settings for
  # stateful data (like database locations and file system formats)
  # are taken. It's NOT the same as the installed NixOS version...
  # you can run NixOS 25.11 with stateVersion "25.05" if you want
  # to keep the old defaults. Only update this when you want to
  # adopt new defaults or upgrade major versions. You can verify
  # installed NixOS version with nixos-version.
  system.stateVersion = "25.11";
  # Import needed modules here. This is going to pull in my hardware-configuration,
  # global configs (stuff shared between all hosts), optional configs, and
  # my user configs for any users I want added to this host.
  imports = [
    # Import the disko disk configuration for this host.
    ./disks.nix
    # Import the specific hardware-configuration.nix for this host.
    ./hardware-configuration.nix
    # Import my global nixos host configs. These are configs
    # I apply to all my hosts.
    ../../common/global
    # Optional configs to import for this host. If an optional
    # config becomes global, and needs to apply to all my hosts,
    # it gets moved to global.
    ../../common/optional/bluetooth.nix
    ../../common/optional/cachyos-kernel.nix
    ../../common/optional/graphics.nix
    ../../common/optional/pipewire.nix
    ../../common/optional/virt-manager.nix
    # Import my user configs.
    ../../common/users/tomwrw
    # Import my desktop.
    ../../common/optional/desktop/gnome
  ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      timeout = 15;
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
    };
  };
}
