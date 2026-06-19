_: {
  den.aspects.ssh.nixos = _: {
    # Enable and configure SSH for all hosts.
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = false;
        AllowAgentForwarding = false;
        MaxAuthTries = 3;
        LoginGraceTime = 30;
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
      };
    };
  };

  # Client side: the FIDO2 sk handles use non-default file names, so ssh
  # won't offer them unless configured. Primary first; ssh falls through
  # to the backup if the primary token isn't present.
  den.aspects.ssh.homeManager = _: {
    programs.ssh = {
      enable = true;
      # Opt out of HM's deprecated `Host *` default block; its values match
      # OpenSSH's own defaults, so dropping it changes nothing.
      enableDefaultConfig = false;
      # settings replaces the deprecated matchBlocks and uses OpenSSH
      # directive names. The sk handles have non-default file names, so ssh
      # won't offer them unless listed here; primary first, backup as
      # fallback when the primary token isn't present.
      settings."github.com" = {
        User = "git";
        IdentitiesOnly = true;
        IdentityFile = [
          "~/.ssh/id_ed25519_sk_primary"
          "~/.ssh/id_ed25519_sk_backup"
        ];
      };
    };
  };
}
