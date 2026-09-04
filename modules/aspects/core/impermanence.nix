{ inputs, ... }:
{
  # The /persist store, and the only consumer of the persist quirk. Aspects name
  # their own paths and nothing else: none of them import impermanence or know
  # whether the machine rolls back at all.
  flake-file.inputs.impermanence.url = "github:nix-community/impermanence";

  den.aspects.impermanence.nixos =
    { persist, lib, ... }:
    {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      # Don't import impermanence's Home Manager module anywhere. The NixOS
      # module adds it to home-manager.sharedModules itself, and importing it
      # again trips an assertion.
      environment.persistence."/persist" = {
        # Per store, so it does not cover the home.persistence entries below.
        hideMounts = true;

        directories = [
          "/var/log"
          # Keeps UID/GID allocation stable with mutableUsers off. Must be
          # mounted before activation, which works because it is in
          # pathsNeededForBoot.
          "/var/lib/nixos"
          # random-seed, the systemd-boot counters and timer stamps. Mounts in
          # stage 2, still ordered before local-fs.target, so the seed is there
          # before systemd wants it.
          "/var/lib/systemd"
          {
            # sudo wants this 0700; impermanence defaults to 0755.
            directory = "/var/db/sudo/lectured";
            mode = "0700";
          }
          "/var/lib/alsa"
          "/var/lib/upower"
        ]
        ++ lib.concatMap (e: e.system.directories or [ ]) persist;

        files = [
          # Bind mounted, not symlinked. impermanence seeds an "uninitialized"
          # file first, which stops systemd-boot's installer choking on an empty
          # machine-id during a fresh deploy; the symlink form hangs the boot
          # right after "Started D-Bus System Message Bus".
          "/etc/machine-id"
        ]
        ++ lib.concatMap (e: e.system.files or [ ]) persist;
      };

      # impermanence already suppresses this in the initrd, but turning it off
      # outright is what actually boots on this hardware.
      systemd.services.systemd-machine-id-commit.enable = false;
    };

  # The user-scope half. It hangs off the host's inclusion of this aspect rather
  # than off the user aspect, on purpose: whether a home is impermanent is a
  # property of the machine, not of the person. provides.to-users runs it once
  # per user scope, so the pool below is that user's and nothing else.
  #
  # Reads only e.home, so the system paths that arrive here from an aspect
  # included at both scopes are ignored rather than misread as home-relative.
  den.aspects.impermanence.provides.to-users.homeManager =
    { persist, lib, ... }:
    {
      home.persistence."/persist" = {
        hideMounts = true;
        directories = lib.concatMap (e: e.home.directories or [ ]) persist;
        files = lib.concatMap (e: e.home.files or [ ]) persist;
      };
    };
}
