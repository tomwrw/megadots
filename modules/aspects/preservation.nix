{ inputs, ... }:
{
  # preservation is a pure NixOS-module flake with no nixpkgs input, so there
  # is no nixpkgs to make it `follows`.
  flake-file.inputs.preservation.url = "github:nix-community/preservation";

  # Quirk: any aspect can emit paths it needs persisted (e.g. secure-boot's
  # /var/lib/sbctl) as an attrset `{ directories = [...]; files = [...]; }`
  # (either key optional). This aspect aggregates them into /persist,
  # decoupling "what needs persisting" (owned by the emitting aspect) from
  # "how persistence works" (this module). Aspects that emit on this quirk do
  # not fail on hosts that omit preservation — there is simply no consumer.
  den.quirks.persist = {
    description = "Extra paths to persist at /persist: { directories, files }";
  };

  # System-level persistence for impermanent (tmpfs-root) hosts. Routes
  # the minimum set of paths needed for a coherent system identity to
  # /persist, plus anything emitted on the `persist` quirk. Per-user
  # persistence (e.g. /home/<user>) lives with the user — see
  # modules/users/<user>/<user>.nix.
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
            "/var/db/sudo/lectured" # don't re-lecture sudo each boot
            "/var/lib/alsa" # sound card mixer state
            "/var/lib/upower" # battery history (laptops)
          ]
          ++ lib.concatMap (e: e.directories or [ ]) persist;
          files = [
            # machine-id persisted as a bind-mount (matches the proven `main`
            # branch). `inInitrd = true` brings it up early so the bootloader
            # install on a fresh nixos-anywhere deploy sees a valid id instead
            # of crashing on an empty one.
            {
              file = "/etc/machine-id";
              inInitrd = true;
            }
            # NB: SSH host keys are NOT bind-mounted from /persist back to
            # /etc/ssh/. Instead `services.openssh.hostKeys` (below)
            # points sshd directly at /persist paths. Bind-mounting empty
            # placeholders on first boot causes sshd-keygen to fail when
            # it tries to `rm` the placeholder to regenerate.
          ]
          ++ lib.concatMap (e: e.files or [ ]) persist;
        };
      };

      # machine-id is bind-mounted from /persist, so systemd's "commit the
      # transient id from tmpfs to disk" service has nothing to do and would
      # fail noisily — disable it (matches the `main` branch).
      systemd.services.systemd-machine-id-commit.enable = false;

      # Make sshd read & generate host keys directly on /persist. On
      # first boot sshd-keygen creates valid keys there; on subsequent
      # boots they're already in place. Survives tmpfs root wipes
      # because /persist is the real btrfs subvolume.
      services.openssh.hostKeys = [
        {
          type = "ed25519";
          path = "/persist/etc/ssh/ssh_host_ed25519_key";
        }
        {
          type = "rsa";
          bits = 4096;
          path = "/persist/etc/ssh/ssh_host_rsa_key";
        }
      ];
    };
}
