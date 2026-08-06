_: {
  # An SSH agent, replacing the one desktop/gnome.nix turns off.
  #
  # gcr-ssh-agent is disabled there because its FIDO2/sk-* support is poor, but
  # nothing took its place: SSH_AUTH_SOCK was unset fleet-wide. Combined with
  # git's commit.gpgsign (apps/dev/git.nix) and a passphrase-protected signing key,
  # that made 'git commit' fail outright in any non-interactive context with
  # "failed to write commit object" - OpenSSH could neither reach an agent nor
  # ask for the passphrase.
  #
  # Included from the user aspect, not a role: a bare homeManager key on a
  # host-scope aspect is silently dropped by den.
  den.aspects.core.security.ssh-agent = {
    nixos = _: {
      # NOTE: the askpass this ends up using is seahorse's, which comes from
      # the GNOME desktop (nixos/modules/programs/seahorse.nix mkDefaults it).
      # NixOS's own default is x11_ssh_askpass - so a non-GNOME host taking
      # this aspect gets an X11 askpass in its closure and should set
      # programs.ssh.askPassword explicitly.
      #
      # NixOS already computes a working askpass but leaves this
      # false unless services.xserver.enable is set - and this fleet is
      # GNOME-on-Wayland. With it false, SSH_ASKPASS is never exported and
      # OpenSSH falls back to its compiled-in $out/libexec/ssh-askpass, which
      # nixpkgs does not build. Hence the confusing "ssh_askpass: exec(...):
      # No such file or directory" rather than a passphrase prompt.
      programs.ssh.enableAskPassword = true;
    };

    homeManager = _: {
      services.ssh-agent.enable = true;

      programs.ssh = {
        enable = true;
        # Home Manager warns that the legacy programs.ssh defaults are going
        # away; opt out now and state only what we actually want.
        enableDefaultConfig = false;
        settings."*" = {
          # Load a key into the agent the first time it is used, so the
          # passphrase is asked for once per session rather than per operation.
          AddKeysToAgent = "yes";
          # Never let a remote host reach back through our agent.
          ForwardAgent = false;
        };
      };

      # Everything 'just deploy' seeds into /persist/home/<user> via
      # nixos-anywhere --extra-files, plus known_hosts. This list must stay in
      # step with that recipe's key loop: a seeded file with no entry here lands
      # in /persist and is never bind-mounted into the home, which looks exactly
      # like the deploy having silently skipped it.
      #
      # The sk_* pairs are FIDO2 handle stubs - useless without the physical
      # token, but regenerating them means an `ssh-keygen -K` round trip. The
      # tomwrw aspect owns their permissions.
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
