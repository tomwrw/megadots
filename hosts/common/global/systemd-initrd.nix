{
  # Enable initrd.
  boot.initrd.systemd.enable = true;
  # Start the vconsole setup only after local-fs.target,
  # else it might have trouble accessing data on disk.
  systemd.services.systemd-vconsole-setup.after = [ "local-fs.target" ];
}
