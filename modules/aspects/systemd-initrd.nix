_: {
  den.aspects.systemd-initrd.nixos = _: {
    boot.initrd.systemd.enable = true;
    systemd.services.systemd-vconsole-setup.after = [ "local-fs.target" ];
  };
}
