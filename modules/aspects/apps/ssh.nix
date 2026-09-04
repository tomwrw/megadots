_: {
  # An SSH client and agent, with ~/.ssh persisted so keys put there survive the
  # rollback.
  #
  # The agent matters because desktop/gnome.nix turns gcr-ssh-agent off (poor
  # FIDO2 support). With nothing in its place SSH_AUTH_SOCK is unset, and
  # together with commit.gpgsign and a passphrased signing key that makes
  # 'git commit' fail with "failed to write commit object".
  #
  # Included from the user aspect rather than a role: den drops a bare
  # homeManager block on a host-scope aspect.
  den.aspects.ssh = {
    # The whole directory, not a list of files. Anything dropped in ~/.ssh then
    # survives by construction, whether it arrived from a deploy, from scp or
    # from ssh-keygen - where a file list needed an invariant to police it,
    # because adding a key to the deploy and forgetting to persist it left the
    # key working until the first reboot.
    persist.home.directories = [ ".ssh" ];

    nixos = _: {
      # NixOS works out a usable askpass but leaves this off unless
      # services.xserver.enable is set. Off, SSH_ASKPASS is never exported and
      # OpenSSH falls back to a binary nixpkgs doesn't build - which is where
      # "ssh_askpass: exec(...): No such file or directory" comes from.
      #
      # The one that ends up used is seahorse's, pulled in by GNOME; a non-GNOME
      # host taking this aspect should set programs.ssh.askPassword itself.
      programs.ssh.enableAskPassword = true;
    };

    homeManager = _: {
      services.ssh-agent.enable = true;

      programs.ssh = {
        enable = true;
        # Home Manager warns the legacy programs.ssh defaults are going away.
        enableDefaultConfig = false;
        settings."*" = {
          # One passphrase prompt a session instead of one per operation.
          AddKeysToAgent = "yes";
          # Never let a remote host reach back through the agent.
          ForwardAgent = false;
        };
      };
    };
  };
}
