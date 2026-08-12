_: {
  # The host-scope consumer of the 'seed' quirk, and the only place that knows
  # how deploy-seeded files are owned. Producers say which of their files
  # 'just deploy' brings; everything below is derived from that.
  megadots.core.seed.description = "Turns the seed quirk into tmpfiles ownership rules and a chown unit, so a deploy can pre-place a user's keys.";

  megadots.core.seed.nixos =
    {
      config,
      lib,
      seed,
      ...
    }:
    let
      # seed entries arrive as { owner; files; }, already resolved against the
      # scope that produced them (see den.quirks.seed), so grouping by owner is
      # just an attrset fold rather than anything to do with provenance.
      owners = lib.unique (map (e: e.owner) seed);
      filesFor = owner: lib.unique (lib.concatMap (e: e.files) (lib.filter (e: e.owner == owner) seed));

      homeOf = owner: config.users.users.${owner}.home;

      # Every ancestor of a file, home-relative: ".config/sops/age/keys.txt"
      # gives .config, .config/sops and .config/sops/age. The old hand-written
      # list had exactly these, which is the point - it was a list of things
      # derivable from the file paths, maintained by hand.
      ancestorsOf =
        file:
        let
          parts = lib.splitString "/" (dirOf file);
        in
        lib.genList (i: lib.concatStringsSep "/" (lib.take (i + 1) parts)) (lib.length parts);

      dirsFor = owner: lib.unique (lib.concatMap ancestorsOf (filesFor owner));

      # 0700 everywhere except .config. These hold key material, but .config is
      # the parent of a great deal more than secrets and plenty of things
      # expect to traverse it.
      dirMode = d: if d == ".config" then "0755" else "0700";

      owned = owner: mode: {
        d = {
          user = owner;
          group = config.users.users.${owner}.group;
          inherit mode;
        };
      };

      # 'd' fixes ownership and mode even though nixos-anywhere seeded these as
      # root. Both sides are listed on purpose, and dropping either one breaks a
      # different boot:
      #
      # - /persist is where 'just deploy' seeds them. impermanence never repairs
      #   an existing persist directory, it copies that directory's owner and
      #   mode onto the live path, so a root-owned /persist entry keeps
      #   re-infecting my home on every activation.
      #
      # - /home is needed because that copy runs during activation, which here
      #   happens in the initrd, while tmpfiles run at sysinit in stage 2
      #   afterwards. Fix only /persist and the live tree stays wrong for the
      #   whole first boot after a deploy. ~/.ssh is a plain directory, not a
      #   bind mount, so correcting /persist doesn't reach it.
      #
      # Getting this wrong broke home-manager and ssh twice. tmpfiles run at
      # sysinit and home-manager-<user> is wantedBy multi-user.target, so the
      # live fixes land first without any explicit ordering.
      entriesFor =
        prefix: owner:
        {
          "${prefix}${homeOf owner}" = owned owner "0700";
        }
        // lib.listToAttrs (
          map (d: lib.nameValuePair "${prefix}${homeOf owner}/${d}" (owned owner (dirMode d))) (dirsFor owner)
        );
    in
    {
      options.megadots.seed = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = { };
        description = ''
          Home-relative files 'just deploy' must seed, keyed by owner. Exists so
          the recipe can read the list out of the config it is deploying instead
          of carrying its own copy - 'nix eval .#nixosConfigurations.<host>.config.megadots.seed'.
        '';
      };

      config = {
        megadots.seed = lib.genAttrs owners filesFor;

        systemd.tmpfiles.settings."10-seed" = lib.mkMerge (
          lib.concatMap (owner: [
            (entriesFor "/persist" owner)
            (entriesFor "" owner)
          ]) owners
        );

        # tmpfiles can own the seeded directories but not the seeded files.
        # systemd-tmpfiles refuses to 'z' a file whose path runs through
        # user-owned directories, which is its protection against symlink
        # attacks, so the rules do nothing and the keys stay root:root 0600.
        # sops-nix then dies with "cannot read keyfile
        # '~/.config/sops/age/keys.txt': permission denied" and takes syncthing
        # with it, since copy-keys needs the decrypted cert. It all looks like a
        # deploy that skipped the keys.
        #
        # So the chown happens from root in a oneshot, not as tmpfiles 'z'
        # entries. I replaced this with 'z' rules once because they were more
        # declarative. They are, and they don't work. Found out on a flatmate
        # deploy.
        #
        # /persist is the side that gets chowned, since it's the source of the
        # bind mount and the live path is the same inode.
        systemd.services = lib.listToAttrs (
          map (
            owner:
            lib.nameValuePair "${owner}-seeded-keys" {
              description = "Own ${owner}'s deploy-seeded key files";
              wantedBy = [ "multi-user.target" ];
              before = [ "home-manager-${owner}.service" ];
              unitConfig.ConditionPathExists = "/persist${homeOf owner}";
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
              # Existence-checked rather than globbed. A missing key is normal,
              # not every host seeds every key, but a chown that actually fails
              # should still fail the unit.
              script = ''
                files=()
                for f in ${
                  lib.concatMapStringsSep " " (f: lib.escapeShellArg "/persist${homeOf owner}/${f}") (filesFor owner)
                }; do
                  [ -e "$f" ] && files+=("$f")
                done
                if [ ''${#files[@]} -gt 0 ]; then
                  chown ${owner}:${config.users.users.${owner}.group} "''${files[@]}"
                fi
              '';
            }
          ) owners
        );
      };
    };
}
