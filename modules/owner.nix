{ config, ... }:
let
  owner = config.flake.meta.owner;
in
{
  flake.meta.owner = {
    username = "tomwrw";
    name = "tomwrw";
    email = "tomwrw@proton.me";
    sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFCIJ1LhkFDBZaZU/bf8Y3XyCXb3RnVxg4gRs6i+XbSe tomwrw@proton.me";
  };

  flake.modules.nixos.base =
    {
      pkgs,
      config,
      ...
    }:
    {
      sops.secrets."password-${owner.username}" = {
        sopsFile = ../secrets/shared.yaml;
        neededForUsers = true;
      };

      users.users.${owner.username} = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets."password-${owner.username}".path;
        shell = pkgs.fish;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [ owner.sshKey ];
      };

      nix.settings.trusted-users = [ owner.username ];

      programs.fish.enable = true;
    };
}
