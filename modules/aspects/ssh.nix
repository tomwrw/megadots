{ ... }:
{
  den.aspects.ssh.nixos =
    { ... }:
    {
      # Enable and configure SSH for all hosts.
      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
        };
      };

      # Configure SSH agent key files.
      security.pam.sshAgentAuth = {
        enable = true;
        authorizedKeysFiles = [ "/etc/ssh/authorized_keys.d/%u" ];
      };
    };
}
