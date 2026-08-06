{ inputs, ... }:
{
  flake-file.inputs.impermanence.url = "github:nix-community/impermanence";

  den.aspects.core.impermanence.nixos =
    { persist, lib, ... }:
    {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      # Nothing imports impermanence's Home Manager module by hand: the NixOS
      # module adds it to home-manager.sharedModules itself (nixos.nix:225-227),
      # and importing it a second time trips an assertion. So a user aspect can
      # just set home.persistence and it is collected here.
      environment.persistence."/persist" = {
        # Keeps the bind mounts out of file-manager sidebars. Per STORE, not
        # global: setting it here does NOT cover home.persistence entries, which
        # carry their own hideMounts (submodule-options.nix:152,311).
        hideMounts = true;

        directories = [
          "/var/log"
          # Under mutableUsers = false this is what makes UID/GID allocation
          # stable across boots; without it a second user would get boot-time
          # IDs that disagree with the ownership of files already on /persist.
          # It needs to be mounted before NixOS activation runs
          # update-users-groups.pl, which impermanence handles because
          # /var/lib/nixos is in utils.pathsNeededForBoot - see the note below.
          "/var/lib/nixos"
          # Holds random-seed, the systemd-boot boot counters and the timer
          # stamps. NOT in pathsNeededForBoot, so unlike the entry above this
          # one is mounted in stage 2 rather than the initrd (nixos.nix:290).
          # Still ordered before local-fs.target, which is ahead of
          # systemd-random-seed.service at sysinit, so the seed is in place
          # before systemd reads it.
          "/var/lib/systemd"
          {
            # Records which accounts have been lectured. sudo creates it 0700
            # and impermanence's default is 0755.
            directory = "/var/db/sudo/lectured";
            mode = "0700";
          }
          "/var/lib/alsa"
          "/var/lib/upower"
        ]
        ++ lib.concatMap (e: e.directories or [ ]) persist;

        files = [
          # Bind-mounted, not symlinked. impermanence does this itself and also
          # seeds an "uninitialized" file first (mount-file.bash), which is what
          # keeps systemd-boot's installer from reading an empty machine-id and
          # dying during a fresh nixos-anywhere deploy. The symlink form is what
          # used to hang this fleet's boot right after "Started D-Bus System
          # Message Bus".
          "/etc/machine-id"
        ]
        ++ lib.concatMap (e: e.files or [ ]) persist;
      };

      # impermanence already suppresses this unit in the initrd and pins
      # ConditionFirstBoot on it in stage 2 (nixos.nix:504-508). Disabling it
      # outright as well is what has actually booted on this hardware.
      systemd.services.systemd-machine-id-commit.enable = false;
    };
}
