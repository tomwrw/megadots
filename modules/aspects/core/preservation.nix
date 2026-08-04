{ inputs, ... }:
{
  flake-file.inputs.preservation.url = "github:nix-community/preservation";

  den.aspects.core.preservation.nixos =
    { persist, lib, ... }:
    {
      imports = [ inputs.preservation.nixosModules.default ];

      preservation = {
        enable = true;
        preserveAt."/persist" = {
          directories = [
            "/var/log"
            {
              # inInitrd because NixOS activation runs update-users-groups.pl
              # from stage-2-init BEFORE stage-2 systemd mounts anything. As a
              # plain entry this directory was still empty at that point, so
              # every boot re-derived the UID/GID allocation from scratch and
              # wrote it to the tmpfs copy, which the persisted one then
              # shadowed. Stable today with one user, but with mutableUsers =
              # false a second user would get boot-time UIDs that disagree with
              # the ownership of files already on /persist and /home.
              directory = "/var/lib/nixos";
              inInitrd = true;
            }
            {
              # inInitrd so random-seed is in place before systemd seeds the
              # kernel RNG. The whole tree is preserved rather than the
              # individual coredump/rfkill/timers/random-seed entries upstream's
              # example lists - that example does not persist the parent, this
              # does, and nesting children under a bind-mounted parent is
              # redundant at best.
              directory = "/var/lib/systemd";
              inInitrd = true;
            }
            {
              # preservation's default directory mode is 0755; sudo creates
              # this one 0700 and it records which accounts have been lectured.
              directory = "/var/db/sudo/lectured";
              mode = "0700";
            }
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
    };
}
