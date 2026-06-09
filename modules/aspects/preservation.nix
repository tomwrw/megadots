{ inputs, ... }:
{
  flake-file.inputs.preservation.url = "github:nix-community/preservation";

  den.quirks.persist = {
    description = "Extra paths to persist at /persist: { directories, files }";
  };

  den.aspects.preservation.nixos =
    { persist, lib, ... }:
    {
      imports = [ inputs.preservation.nixosModules.default ];

      preservation = {
        enable = true;
        preserveAt."/persist" = {
          directories = [
            "/var/log"
            "/var/lib/nixos"
            "/var/lib/systemd"
            "/etc/NetworkManager/system-connections"
            "/var/db/sudo/lectured"
            "/var/lib/alsa"
            "/var/lib/upower"
          ]
          ++ lib.concatMap (e: e.directories or [ ]) persist;
          files = [
            {
              file = "/etc/machine-id";
              inInitrd = true;
            }
          ]
          ++ lib.concatMap (e: e.files or [ ]) persist;
        };
      };

      systemd.services.systemd-machine-id-commit.enable = false;

      services.openssh.hostKeys = [
        {
          type = "ed25519";
          path = "/persist/etc/ssh/ssh_host_ed25519_key";
        }
      ];
    };
}
