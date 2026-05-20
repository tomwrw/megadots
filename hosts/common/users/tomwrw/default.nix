{
  config,
  pkgs,
  ...
}:
let
  # Configure user settings for NixOS.
  username = "tomwrw";
  sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFCIJ1LhkFDBZaZU/bf8Y3XyCXb3RnVxg4gRs6i+XbSe tomwrw@proton.me";
  # Store the hostname for deriving the home file path.
  hostname = config.networking.hostName;
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  # Read the sops managed secret for my user password.
  sops.secrets."users/${username}/hashedPassword" = {
    neededForUsers = true;
  };

  users.mutableUsers = false;
  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [ sshKey ];
    packages = [ pkgs.home-manager ];
    extraGroups = ifTheyExist [
      "audio"
      "docker"
      "git"
      "i2c"
      "libvirtd"
      "mysql"
      "network"
      "plugdev"
      "podman"
      "openrazer"
      "video"
      "input"
      "vboxusers"
      "wheel"
      "kvm"
    ];
    # This uses the sops-nix managed password for my user.
    hashedPasswordFile = config.sops.secrets."users/${username}/hashedPassword".path;
  };

  # Import the Home Manager config for this user on this host.
  home-manager.users.${username} = import ../../../../home/${username}/${hostname}.nix;
}
