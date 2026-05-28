{ inputs, ... }:
{
  imports = [
    inputs.preservation.nixosModules.default
  ];

  # machine-id is bind-mounted from /persist, so systemd's "commit transient
  # id from tmpfs to disk" service has nothing to do and fails noisily. Disable
  # it — the persisted file is already authoritative.
  systemd.services.systemd-machine-id-commit.enable = false;

  preservation = {
    enable = true;
    preserveAt."/persist" = {
      files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
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
  };
}
