_: {
  # Siblings now, so it is worth saying what separates this from
  # core/hardening.nix: this file sets the baseline - the things that should be
  # true of any machine before anyone thinks about threat models. hardening.nix
  # narrows those defaults with sysctls and kernel parameters that trade some
  # convenience or compatibility for a smaller attack surface. If a setting
  # would be uncontroversial on a stock NixOS install it belongs here; if it is
  # a deliberate tightening it belongs there.
  # Baseline system security: polkit, rtkit, immutable users and wheel-only sudo.
  den.aspects.security.nixos = _: {
    security.rtkit.enable = true;
    security.polkit.enable = true;

    # Only wheel can execute the setuid sudo binary. Everything of mine that
    # needs root ('just rebuild', activation) runs as wheel anyway.
    security.sudo.execWheelOnly = true;

    # Users come from the config or not at all. This used to live in the tomwrw
    # aspect, so a host without that user quietly got mutable users. It's also
    # why persisting /var/lib/nixos matters, see core/impermanence.nix.
    users.mutableUsers = false;

    security.pam.loginLimits = [
      {
        domain = "@wheel";
        item = "nofile";
        type = "soft";
        value = "65536";
      }
      {
        domain = "@wheel";
        item = "nofile";
        type = "hard";
        value = "131072";
      }
    ];
  };
}
