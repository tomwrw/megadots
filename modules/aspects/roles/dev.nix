{ den, ... }:
{
  # Dev tooling, opted into per host rather than following the user onto every
  # machine. Keeping the decision in a role means no host name appears under
  # modules/users/.
  den.aspects.dev = {
    # The host half: a dev machine is one that can run VMs.
    includes = [
      den.aspects.libvirt
    ];

    # The user half, given to every user on a host taking this role. git is not
    # here - it is baseline for someone who signs commits, and the signing
    # identity lives on the user anyway.
    provides.to-users.includes = [
      den.aspects.claude-code
      den.aspects.code-cursor
      den.aspects.vscodium
    ];
  };
}
