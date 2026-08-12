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
  megadots.apps.security.ssh = {
    description = "An SSH client and agent, with ~/.ssh persisted so keys put there survive the rollback.";

    # The whole directory, not a list of files, and that is the point.
    #
    # This used to name every key by hand and emit them as a 'seed' quirk, so
    # that core.seed could derive tmpfiles ownership and a chown unit, and the
    # justfile could copy exactly those files. Three mechanisms, all to answer
    # "which files, and who owns them". nixos-anywhere answers both itself:
    # --extra-files puts the tree in place and --chown fixes the ownership,
    # during the install, where the problem actually is.
    #
    # A directory entry also makes "seeded implies persisted" structural. The
    # old file list needed an invariant to police it, because adding a key to
    # the deploy and forgetting to persist it left the key working until the
    # first reboot. Anything dropped in ~/.ssh now survives by construction,
    # whether it arrived from a deploy, from scp, or from ssh-keygen.
    home-persist.directories = [ ".ssh" ];

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

    };
  };
}
