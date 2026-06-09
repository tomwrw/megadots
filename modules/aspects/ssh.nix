{ ... }:
{
  den.aspects.ssh.nixos =
    { ... }:
    {
      # Enable and configure SSH for all hosts.
      services.openssh = {
        enable = true;
        openFirewall = true;
        # hostKeys = [
        #   {
        #     path = "/persist/etc/ssh/ssh_host_ed25519_key";
        #     type = "ed25519";
        #   }
        # ];
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
          X11Forwarding = false;
          AllowAgentForwarding = true;
          MaxAuthTries = 3;
          LoginGraceTime = 30;
          ClientAliveInterval = 300;
          ClientAliveCountMax = 2;
        };
      };

      # Configure SSH agent key files.
      security.pam.sshAgentAuth = {
        enable = true;
        authorizedKeysFiles = [ "/etc/ssh/authorized_keys.d/%u" ];
      };
    };
}
