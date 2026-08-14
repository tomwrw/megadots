{ den, megadots, ... }:
{
  # Extra dev tooling, opted into per host instead of following me onto every
  # machine. Same thinking as roles/gaming.nix - keeping the decision in a role
  # means no host name ever shows up under modules/users/.
  den.aspects.roles.dev = {
    # The host half. libvirt used to be listed directly on endgame, which meant
    # the role described only user apps and a machine's dev capability lived
    # somewhere else entirely. A dev host is a machine that can run VMs.
    includes = [
      megadots.virtualisation.libvirt
    ];

    # vscodium and claude-code moved here out of the tomwrw aspect's
    # unconditional list. They were following me onto flatmate, which takes no
    # dev role - so the README's claim that "dev" is what separates the two
    # hosts was very nearly untrue. git stays on the user: it is baseline for
    # someone who signs commits, and the signing identity lives there anyway.
    provides.to-users.includes = [
      megadots.apps.dev.code-cursor
      megadots.apps.dev.vscodium
      megadots.apps.dev.claude-code
    ];
  };
}
