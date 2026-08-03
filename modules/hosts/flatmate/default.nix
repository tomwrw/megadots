{ den, ... }:
{
  den.aspects.flatmate.includes = [
    den.aspects.roles.default
    den.aspects.roles.workstation
    den.aspects.core.boot.systemd-boot
    den.aspects.hardware.surface-pro
    den.aspects.hardware.flatmate
  ];
}
