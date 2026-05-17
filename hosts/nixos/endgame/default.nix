{ pkgs, ... }:
{
  # Set the host-specific hostname here.
  networking = {
    hostName = "endgame";
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
    ../../common/optional/ephemeral-btrfs.nix
    ../../common/optional/gaming.nix
    ../../common/optional/graphics.nix
    ../../common/optional/lanzaboote.nix
    ../../common/optional/pipewire.nix
    ../../common/optional/virt-manager.nix
    # Import my user configs.
    ../../common/users/tomwrw
    # Import my desktop.
    ../../common/optional/wm/gnome/gnome.nix
  ];
  # Boot loader settings are usually unique to my hosts
  # since some systems will dual boot with Windows. For
  # that reason, I keep the boot loader settings in the
  # configuration.nix for each host.
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      timeout = 15;
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        windows = {
          "windows" =
            let
              # To determine the name of the windows boot drive, boot into edk2 first, then run
              # `map -c` to get drive aliases, and try out running `FS1:`, then `ls EFI` to check
              # which alias corresponds to which EFI partition.
              boot-drive = "FS2";
            in
            {
              title = "Windows";
              efiDeviceHandle = boot-drive;
              sortKey = "y_windows";
            };
        };
        # edk2 can be used to determine the Windows boot-drive value.
        # I disable it after I've got the code as it is no longer
        # needed, but I like to leave it in my configs.
        edk2-uefi-shell.enable = false;
        edk2-uefi-shell.sortKey = "z_edk2";
      };
    };
    kernelParams = [ ];
  };
  # Host specific apps go here. These will only be
  # installed on this host.
  environment.systemPackages = with pkgs; [
    age
    azure-cli
    hello
    npins
    unetbootin
  ];
}
