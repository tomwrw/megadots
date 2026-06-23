_: {
  den.aspects.ssh.nixos = _: {
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

  den.aspects.ssh.homeManager = _: {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
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
