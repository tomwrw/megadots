_: {
  den.aspects.core.security.openssh =
    { host, ... }:
    {
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
        };

        # LAN-scoped instead of openFirewall's global allow - see core.networking
        # for the same treatment applied to mDNS.
        networking.firewall.interfaces.${host.network.lanInterface}.allowedTCPPorts = [ 22 ];
      };
    };
}
