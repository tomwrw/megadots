_: {
  den.aspects.core.security.nixos = _: {
    security.rtkit.enable = true;
    security.polkit.enable = true;

    # Only wheel members can even execute the setuid sudo binary. Everything
    # that needs root here ('just rebuild', activation) runs as a wheel member.
    security.sudo.execWheelOnly = true;

    # Fleet policy, not per-user policy: users come from the config or not at
    # all. Lived in the tomwrw aspect before, which meant a host without that
    # user would silently fall back to mutable users. It is also what makes
    # persisting /var/lib/nixos matter - see core/preservation.nix.
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
