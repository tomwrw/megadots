{ ... }:
{
  den.aspects.systemd-initrd.nixos =
    { ... }:
    {
      boot.initrd.systemd.enable = true;
      systemd.services.systemd-vconsole-setup.after = [ "local-fs.target" ];
    };
}
