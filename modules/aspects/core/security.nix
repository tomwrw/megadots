_: {
  den.aspects.core.security.nixos = _: {
    security.rtkit.enable = true;
    security.polkit.enable = true;

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
