{
  config,
  pkgs,
  ...
}:
let
  # Configure user settings for NixOS.
  username = "tomwrw";
  # Store the hostname for deriving the home file path.
  hostname = config.networking.hostName;
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  # Read the sops managed secret for my user password.
  sops.secrets."users/${username}/password" = {
    neededForUsers = true;
  };

  nix.settings.trusted-users = [ username ];

  users.mutableUsers = false;
  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPiQIe8ejl2D9ZLBZCHYyt7Iyh9jFHZ5iMYydq57DnDSAAAACnNzaDp0b213cnc= tomwrw-primary"
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIG+ODAzUIgoEOgf1+ijqOPCljmYoXn9HETmJ1kP5cuAFAAAACnNzaDp0b213cnc= tomwrw-backup"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFCIJ1LhkFDBZaZU/bf8Y3XyCXb3RnVxg4gRs6i+XbSe tomwrw"
    ];
    packages = [ pkgs.home-manager ];
    extraGroups = ifTheyExist [
      "audio"
      "docker"
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
    hashedPasswordFile = config.sops.secrets."users/${username}/password".path;
  };

  # Import the Home Manager config for this user on this host.
  home-manager.users.${username} = import ../../../../home/${username}/${hostname}.nix;
}
