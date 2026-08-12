_: {
  megadots.core.security.openssh = {
    description = "An sshd accepting keys only, firewalled to the LAN by the firewall quirk rather than openFirewall.";

    nixos = _: {
      services.openssh = {
        enable = true;
        # Upstream defaults this to true, so it has to be an explicit false or
        # sshd reopens port 22 on every interface.
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

        # Host keys live on /persist because / gets wiped every boot. Setting
        # the path here and not in the impermanence aspect means a host can't
        # lose its identity, and break every known_hosts, just by skipping that
        # aspect. Only listing ed25519 also drops the default RSA key.
        hostKeys = [
          {
            type = "ed25519";
            path = "/persist/etc/ssh/ssh_host_ed25519_key";
          }
        ];
      };
    };

    # LAN only, instead of openFirewall opening it everywhere. core.networking
    # puts it on the right interface.
    firewall.tcp = [ 22 ];
  };
}
