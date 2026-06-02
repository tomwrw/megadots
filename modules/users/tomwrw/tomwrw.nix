{
  lib,
  den,
  ...
}:
{
  den.aspects.tomwrw =
    { host, ... }:
    {

      includes = [
        den.provides.primary-user
        (den.provides.user-shell "zsh")
        den.provides.define-user
      ];

      nixos =
        {
          pkgs,
          config,
          ...
        }:
        {
          users.mutableUsers = false;
          users.users.tomwrw = {
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFCIJ1LhkFDBZaZU/bf8Y3XyCXb3RnVxg4gRs6i+XbSe tomwrw@proton.me"
            ];
            extraGroups = [
              "disk"
              "i2c"
              "networkmanager"
              "wheel"
            ];
            initialPassword = "changeme";
          };
        };

      homeManager =
        { pkgs, ... }:
        {
          home.username = "tomwrw";
          home.homeDirectory = "/home/tomwrw";
          home.stateVersion = "26.05";

          programs.git.settings.user.name = "tomwrw";
          programs.git.settings.user.email = "tomwrw@proton.me";
        };

      provides.spectre = {
        includes = [
          den.aspects.gaming
        ];

        # Persistence rules that belong to *this* user on an impermanent
        # host. The host owns "system identity should survive a wipe"
        # (machine-id, sshd keys); the user owns "my home should survive
        # a wipe." Routed via mutual-provider so it only fires when
        # tomwrw is on spectre.
        nixos =
          { ... }:
          {
            preservation.preserveAt."/persist".directories = [
              {
                directory = "/home/tomwrw";
                user = "tomwrw";
                group = "users";
                mode = "0700";
              }
            ];
          };
      };
    };
}
