_: {
  den.aspects.core.security.openssh = {
    nixos = _: {
      services.openssh = {
        enable = true;
        # Defaults to true upstream - must be explicit false, not just
        # omitted, or sshd's own default reopens port 22 globally.
        openFirewall = false;
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

        # Host identity lives on /persist because / is a tmpfs. Stating it
        # here rather than in the preservation aspect means a host that takes
        # this aspect cannot end up silently regenerating its host key (and
        # tripping every client's known_hosts) just because it skipped the
        # state aspect. Listing only ed25519 also drops the default RSA key.
        hostKeys = [
          {
            type = "ed25519";
            path = "/persist/etc/ssh/ssh_host_ed25519_key";
          }
        ];
      };
    };

    # LAN-scoped instead of openFirewall's global allow. core.networking
    # aggregates this onto the host's LAN interface.
    firewall.tcp = [ 22 ];
  };
}
