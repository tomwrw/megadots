{ pkgs, ... }:
{
  home.packages = [
    pkgs.ente-desktop
  ];

  # Mostly cloud-backed, lower urgency than ente-auth. Path unconfirmed.
  home.persistence."/persist".directories = [
    ".config/ente-desktop"
  ];
}
