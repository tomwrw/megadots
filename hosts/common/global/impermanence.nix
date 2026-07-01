{ inputs, ... }:
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  # machine-id is bind-mounted from /persist, so systemd's "commit transient
  # id from tmpfs to disk" service has nothing to do and fails noisily. Disable
  # it — the persisted file is already authoritative.
  systemd.services.systemd-machine-id-commit.enable = false;

  environment.persistence."/persist" = {
    # impermanence bind-mounts everything in initrd automatically (since
    # boot.initrd.systemd.enable is set globally) — no per-file inInitrd
    # flag like preservation had.
    files = [
      "/etc/machine-id"
    ];
    directories = [
      "/var/lib/nixos"
      "/var/log"
      "/etc/NetworkManager/system-connections"
      "/etc/wireguard"
      "/var/db/sudo/lectured"
      "/var/lib/alsa"
      "/var/lib/systemd"
      "/var/lib/sops-nix"
      "/var/lib/udisks2"
      "/var/lib/upower"
    ];
  };
}
