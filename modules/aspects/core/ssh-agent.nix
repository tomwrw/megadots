_: {
  # An SSH agent, replacing the one desktop/gnome.nix turns off.
  #
  # gcr-ssh-agent is disabled there because its FIDO2/sk-* support is poor, but
  # nothing took its place: SSH_AUTH_SOCK was unset fleet-wide. Combined with
  # git's commit.gpgsign (apps/git.nix) and a passphrase-protected signing key,
  # that made 'git commit' fail outright in any non-interactive context with
  # "failed to write commit object" - OpenSSH could neither reach an agent nor
  # ask for the passphrase.
  #
  # Included from the user aspect, not a role: a bare homeManager key on a
  # host-scope aspect is silently dropped by den.
  den.aspects.core.security.ssh-agent = {
    nixos = _: {
      # NixOS already computes a working askpass (seahorse) but leaves this
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
    };
  };
}
