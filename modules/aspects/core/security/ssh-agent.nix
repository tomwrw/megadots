_: {
  # An SSH agent, replacing the one desktop/gnome.nix turns off.
  #
  # gcr-ssh-agent is off there because its FIDO2 support is poor, but nothing
  # took its place, so SSH_AUTH_SOCK was unset everywhere. Together with git's
  # commit.gpgsign and a passphrased signing key, that made 'git commit' fail
  # with "failed to write commit object" any time I wasn't at a terminal.
  #
  # Included from the user aspect and not a role, because den drops a bare
  # homeManager block on a host-scope aspect.
  den.aspects.core.security.ssh-agent = {
    nixos = _: {
      # The askpass I end up with is seahorse's, pulled in by the GNOME
      # desktop. NixOS defaults to x11_ssh_askpass, so a non-GNOME host taking
      # this aspect should set programs.ssh.askPassword itself.
      #
      # NixOS works out a usable askpass but leaves this off unless
      # services.xserver.enable is set, and I'm on GNOME under Wayland. Off,
      # SSH_ASKPASS never gets exported and OpenSSH falls back to a binary
      # nixpkgs doesn't build, which is where the baffling "ssh_askpass:
      # exec(...): No such file or directory" comes from.
      programs.ssh.enableAskPassword = true;
    };

    homeManager = _: {
      services.ssh-agent.enable = true;

      programs.ssh = {
        enable = true;
        # Home Manager warns the legacy programs.ssh defaults are going away,
        # so opt out now and set only what I want.
        enableDefaultConfig = false;
        settings."*" = {
          # Add a key to the agent the first time I use it, so I get one
          # passphrase prompt a session instead of one per operation.
          AddKeysToAgent = "yes";
          # Never let a remote host reach back through my agent.
          ForwardAgent = false;
        };
      };

      # Everything 'just deploy' seeds into /persist/home/<user>, plus
      # known_hosts. Keep this in step with that recipe's key loop. A seeded
      # file with no entry here sits in /persist and never gets mounted into
      # my home, which looks just like the deploy having skipped it.
      #
      # The sk_* pairs are FIDO2 handle stubs, useless without the token, but
      # regenerating them means an 'ssh-keygen -K' round trip. The tomwrw
      # aspect owns their permissions.
      home.persistence."/persist".files = [
        ".ssh/known_hosts"
        ".ssh/id_ed25519"
        ".ssh/id_ed25519.pub"
        ".ssh/id_ed25519_sk_primary"
        ".ssh/id_ed25519_sk_primary.pub"
        ".ssh/id_ed25519_sk_backup"
        ".ssh/id_ed25519_sk_backup.pub"
      ];
    };
  };
}
