{ inputs, ... }:
{
  flake-file.inputs.impermanence.url = "github:nix-community/impermanence";

  den.aspects.core.impermanence.nixos =
    { persist, lib, ... }:
    {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      # Don't import impermanence's Home Manager module anywhere. The NixOS
      # module adds it to home-manager.sharedModules itself, and importing it
      # again trips an assertion. Aspects just set home.persistence and it gets
      # collected here.
      environment.persistence."/persist" = {
        # Keeps the bind mounts out of the Files sidebar. It's per store, so it
        # doesn't cover home.persistence entries - those set their own in
        # users/tomwrw.
        hideMounts = true;

        directories = [
          "/var/log"
          # Keeps UID/GID allocation stable with mutableUsers off. Without it a
          # second user would get boot-time IDs that don't match what's already
          # on /persist. It has to be mounted before activation, which works
          # because it's in pathsNeededForBoot.
          "/var/lib/nixos"
          # random-seed, the systemd-boot counters and timer stamps. Not in
          # pathsNeededForBoot, so this one mounts in stage 2 and not the
          # initrd. Still ordered before local-fs.target, so the seed is there
          # before systemd wants it.
          "/var/lib/systemd"
          {
            # Tracks who's had the sudo lecture. sudo wants it 0700,
            # impermanence defaults to 0755.
            directory = "/var/db/sudo/lectured";
            mode = "0700";
          }
          "/var/lib/alsa"
          "/var/lib/upower"
        ]
        ++ lib.concatMap (e: e.directories or [ ]) persist;

        files = [
          # Bind mounted, not symlinked. impermanence seeds an "uninitialized"
          # file first, which stops systemd-boot's installer choking on an
          # empty machine-id during a fresh deploy. The symlink form is what
          # used to hang my boot right after "Started D-Bus System Message
          # Bus".
          "/etc/machine-id"
        ]
        ++ lib.concatMap (e: e.files or [ ]) persist;
      };

      # impermanence already suppresses this in the initrd, but turning it off
      # outright is what actually boots on my hardware.
      systemd.services.systemd-machine-id-commit.enable = false;
    };
}
