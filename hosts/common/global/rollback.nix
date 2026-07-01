_: {
  # boot.initrd.systemd.enable is already set globally by systemd-initrd.nix.
  boot.initrd.systemd.services.rollback = {
    description = "Rollback BTRFS root subvolume to a pristine state";
    wantedBy = [ "initrd.target" ];
    requires = [ "systemd-cryptsetup@crypted.service" ];
    after = [ "systemd-cryptsetup@crypted.service" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir /mnt
      mount -t btrfs -o subvol=/ /dev/mapper/crypted /mnt
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
  };
}
