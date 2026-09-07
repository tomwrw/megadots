{ config, lib, ... }:
let
  # The two things the old justfile kept as variables at the top of the file.
  # user is the account these tasks reach a host through; usbDefault is a
  # removable mount, so it takes an environment override rather than an edit.
  user = "tomwrw";
  usbDefault = "/run/media/tomwrw/SURVIVOR/keys";

  # Derived, not hardcoded, the same way flake/checks.nix derives its per-host
  # checks: a newly added host is never silently missing from the list a task
  # will accept.
  hosts = lib.attrNames config.flake.nixosConfigurations;
  hostList = lib.concatStringsSep " " hosts;

  # Every task operates on '.', exactly as the recipes did. That keeps the
  # division core/nix.nix documents: these are the in-the-checkout, either-host
  # path, and the n* aliases are the this-machine, from-anywhere path. Baking
  # inputs.self instead would make every task act on the last committed tree,
  # which is wrong for a build-and-test loop.
  requireFlake = ''
    if [ ! -e flake.nix ]; then
      echo "no flake.nix in $PWD - these tasks run from the checkout" >&2
      exit 1
    fi
  '';

  # The check the justfile never had: it passed a typo straight through to
  # nixos-rebuild, which failed deep inside nix with nothing useful to read.
  # A loop rather than a case: the host list is baked in at eval time, so a
  # 'case " endgame flatmate " in' has a constant subject and shellcheck rejects
  # it (SC2194). Worth noting that it caught this at build time - the justfile
  # would have shipped it.
  requireHost = ''
    host="''${1:-}"
    matched=""
    for h in ${hostList}; do
      if [ "$h" = "$host" ]; then
        matched=1
        break
      fi
    done
    if [ -z "$matched" ]; then
      echo "no such host: ''${host:-<none>}" >&2
      echo "valid hosts: ${hostList}" >&2
      exit 1
    fi
    shift
  '';
in
{
  # The repo's own tasks, as flake apps. Replaces a justfile.
  #
  # Six of its fourteen recipes are gone rather than ported: fmt, check, update,
  # gc, default and secrets-edit only wrapped 'nix fmt', 'nix flake check',
  # 'nix flake update', nix-collect-garbage, 'just --list' and sops. The n*
  # aliases in core/nix.nix already do the first four from any directory, which
  # a justfile could never do, and 'nix flake show' lists these.
  #
  # writeShellApplication and not a plain script, so shellcheck runs over every
  # one of them at build time. The deploy recipe was 25 lines of unchecked bash
  # that formats disks.
  perSystem =
    { pkgs, ... }:
    let
      task =
        {
          name,
          description,
          runtimeInputs ? [ ],
          text,
        }:
        pkgs.writeShellApplication {
          inherit name runtimeInputs;
          meta.description = description;
          text = requireFlake + text;
        };

      # Install HOST from scratch over SSH with nixos-anywhere. FORMATS ITS DISKS.
      # The USB mirrors the destination, so there is no manifest and no mapping:
      #
      #   <usb>/hosts/<host>/age.txt     -> /persist/var/lib/sops-nix/key.txt
      #   <usb>/users/<user>/**          -> /persist/home/<user>/**
      #
      # Everything lands under /persist and not /home, because / (and so /home)
      # goes back to a blank snapshot every boot; impermanence bind mounts it
      # into the live home. Whatever a user needs, put it on the USB at the path
      # it should have in their home - .ssh/id_ed25519,
      # .config/sops/age/keys.txt - and it arrives there. Adding a key is a copy
      # on the USB and nothing in this repo.
      #
      # This replaced a 'seed' quirk, a host-scope consumer aspect that derived
      # tmpfiles ownership and a chown unit, a machine-readable option, a recipe
      # to read it and four invariants to police it - all of which existed
      # because --extra-files copies as root. --chown does that job during the
      # install instead of on every boot, which is where it belonged.
      deploy = task {
        name = "deploy";
        description = "Install HOST from scratch over SSH. FORMATS ITS DISKS.";
        # nixos-anywhere from this flake's own nixpkgs rather than
        # github:nix-community/nixos-anywhere at HEAD. Deploying is the one
        # thing that formats disks, so it should be the least improvised step I
        # have. This is why flake/deploy.nix used to exist.
        runtimeInputs = [
          pkgs.nixos-anywhere
          pkgs.coreutils
        ];
        text = ''
          ${requireHost}
          usb="''${MEGADOTS_USB:-${usbDefault}}"
          if [ ! -d "$usb" ]; then
            echo "no key material at $usb - is the USB mounted?" >&2
            echo "override with MEGADOTS_USB=/path/to/keys" >&2
            exit 1
          fi

          staging=$(mktemp -d)
          trap 'rm -rf "$staging"' EXIT
          install -Dm600 "$usb/hosts/$host/age.txt" \
            "$staging/persist/var/lib/sops-nix/key.txt"

          # -a keeps the modes off the USB, so a 0600 private key stays 0600 and
          # sshd/sops do not refuse it. Check them there, not here.
          for u in "$usb"/users/*/; do
            [ -d "$u" ] || continue
            install -d "$staging/persist/home/$(basename "$u")"
            cp -a "$u." "$staging/persist/home/$(basename "$u")/"
          done

          # uid:gid rather than names: this runs against the installer image,
          # which has no account for my user. 1000:100 is the first normal user
          # and the 'users' group, which is what den.batteries.primary-user
          # creates.
          chown_args=()
          for u in "$usb"/users/*/; do
            [ -d "$u" ] || continue
            chown_args+=(--chown "/persist/home/$(basename "$u")" 1000:100)
          done

          nixos-anywhere \
            --disko-mode disko \
            --extra-files "$staging" \
            "''${chown_args[@]}" \
            --flake ".#$host" \
            --target-host "nixos@$host" \
            "$@"
        '';
      };

      build = task {
        name = "build";
        description = "Build HOST's closure locally, no activation.";
        text = ''
          ${requireHost}
          # The CachyOS cache, which the justfile kept in a 'cachyos-cache'
          # variable. IFD is on because stylix reads its base16 scheme out of a
          # derivation at eval time.
          nixos-rebuild build --flake ".#$host" \
            --option allow-import-from-derivation true \
            --option extra-substituters 'https://nyx-cache.chaotic.cx/' \
            --option extra-trusted-public-keys 'nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk=' \
            "$@"
        '';
      };

      rebuild = task {
        name = "rebuild";
        description = "Switch HOST to a locally-built closure over SSH.";
        text = ''
          ${requireHost}
          nixos-rebuild switch --flake ".#$host" \
            --target-host "${user}@$host" --sudo --ask-sudo-password "$@"
        '';
      };

      # Not called "diff": that is diffutils' command, and these land on $PATH
      # inside nix develop, where shadowing it would be a nasty surprise. Every
      # other task name is clear - checked against PATH, not assumed.
      diff-host = task {
        name = "diff-host";
        description = "Build HOST locally and show what would change versus the running system.";
        # The Nix equivalent of just's 'diff HOST: (build HOST)' dependency.
        runtimeInputs = [
          build
          pkgs.nvd
        ];
        text = ''
          ${requireHost}
          build "$host"
          nvd diff /run/current-system result
        '';
      };

      # Read from the config that actually opens it at boot instead of
      # rebuilding it from the disk id, so it survives repartitioning. The old
      # version appended "-part2" and would have pointed at the ESP if the
      # partition order changed.
      luks-device = task {
        name = "luks-device";
        description = "Print the LUKS device path for HOST.";
        text = ''
          ${requireHost}
          nix eval --raw ".#nixosConfigurations.$host.config.boot.initrd.luks.devices.crypted.device"
        '';
      };

      enroll-fido2 = task {
        name = "enroll-fido2";
        description = "Add the inserted FIDO2 token as a LUKS keyslot on HOST.";
        runtimeInputs = [
          luks-device
          pkgs.openssh
        ];
        text = ''
          ${requireHost}
          dev="$(luks-device "$host")"
          ssh -t "${user}@$host" \
            sudo systemd-cryptenroll --fido2-device=auto --fido2-with-client-pin=yes "$dev"
        '';
      };

      unenroll-fido2 = task {
        name = "unenroll-fido2";
        description = "Remove all FIDO2 keyslots from HOST, leaving the passphrase.";
        runtimeInputs = [
          luks-device
          pkgs.openssh
        ];
        text = ''
          ${requireHost}
          dev="$(luks-device "$host")"
          if [ "$host" = "$(hostname)" ]; then
            sudo cryptsetup open --test-passphrase "$dev" \
              && sudo systemd-cryptenroll --wipe-slot=fido2 "$dev"
          else
            ssh -t "${user}@$host" \
              "sudo cryptsetup open --test-passphrase '$dev' && sudo systemd-cryptenroll --wipe-slot=fido2 '$dev'"
          fi
        '';
      };

      # Left interactive on purpose. This is exactly the moment to look at the
      # per-recipient diff sops prints before it re-encrypts anything.
      secrets-updatekeys = task {
        name = "secrets-updatekeys";
        description = "Re-sync sops recipients on every secrets file against .sops.yaml.";
        runtimeInputs = [ pkgs.sops ];
        text = ''
          for f in secrets/hosts/*.yaml secrets/users/*.yaml; do
            sops updatekeys "$f"
          done
        '';
      };

      tasks = {
        inherit
          deploy
          build
          rebuild
          diff-host
          luks-device
          enroll-fido2
          unenroll-fido2
          secrets-updatekeys
          ;
      };
    in
    {
      # Three exposures, one definition. packages so 'nix build .#deploy' runs
      # shellcheck over it, apps so 'nix run .#deploy endgame' works, and
      # flake/devshell.nix puts the same derivations on $PATH.
      packages = tasks;

      # program takes the derivation directly: flake-parts coerces it through
      # lib.getExe, and writeShellApplication sets meta.mainProgram. The
      # description is what 'nix flake show' prints.
      apps = lib.mapAttrs (_: p: {
        program = p;
        meta.description = p.meta.description;
      }) tasks;
    };
}
