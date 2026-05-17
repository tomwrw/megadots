_:
let
  rollbackScript = ''
    mkdir /mnt
    mount -t btrfs -o subvol=/ /dev/disk/by-label/nixos /mnt
    btrfs subvolume list -o /mnt/root | cut -f 9- -d ' ' | while read subvolume; do
      echo "deleting subvolume: /$subvolume..."
      btrfs subvolume delete "/mnt/$subvolume" 1>/dev/null
    done &&
    btrfs subvolume delete /mnt/root 1>/dev/null
    echo "restoring blank /root subvolume..."
    btrfs subvolume snapshot /mnt/root-blank /mnt/root 1>/dev/null
    rm -rf /mnt/root/root && mkdir /mnt/root/root
    umount /mnt
  '';
in
{
  # With root rolled back on every boot, /etc/ssh is on the ephemeral
  # subvol — but NixOS runs the neededForUsers sops activation step
  # inside initrd, before the impermanence bind mounts are set up.
  # Read the SSH host key from /persist directly (the underlying btrfs
  # subvol IS mounted in initrd).
  sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

  boot.initrd = {
    enable = true;
    supportedFilesystems = [ "btrfs" ];
    systemd.services.rollback = {
      description = "Rollback BTRFS root subvolume to a pristine state";
      wantedBy = [ "initrd.target" ];
      requires = [ "dev-disk-by\\x2dlabel-nixos.device" ];
      after = [
        "dev-disk-by\\x2dlabel-nixos.device"
        "systemd-cryptsetup@nixos.service"
      ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = rollbackScript;
    };
  };
}
