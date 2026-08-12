let
  # The FIDO2 pairs are handle stubs, useless without the token, but
  # regenerating them means an 'ssh-keygen -K' round trip, so 'just deploy'
  # brings them over from the USB.
  seededKeys =
    builtins.concatMap
      (k: [
        ".ssh/${k}"
        ".ssh/${k}.pub"
      ])
      [
        "id_ed25519"
        "id_ed25519_sk_primary"
        "id_ed25519_sk_backup"
      ];
in
{
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
    description = "An SSH client and agent. Names the private keys a deploy has to seed, via the seed quirk.";

    # The single list. It used to live here, in the justfile's key loop and in
    # the tomwrw aspect's chown globs, bound together by comments that admitted
    # the drift had bitten twice. core.seed now derives the tmpfiles ownership,
    # the chown unit and what 'just deploy' copies, all from this.
    # Bare, not through provides.to-users like core/security/sops.nix does,
    # because this aspect is only ever included from the user aspect. den
    # resolves a quirk thunk against the producing scope's context, and 'user'
    # is in that context here.
    seed =
      { user, ... }:
      {
        owner = user.userName;
        files = seededKeys;
      };

    # known_hosts is persisted but never seeded - the deploy has nothing to put
    # there yet. core.seed asserts the other direction, that everything seeded
    # is also persisted, so this only has to add what seeding doesn't cover.
    home-persist.files = [ ".ssh/known_hosts" ] ++ seededKeys;

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
