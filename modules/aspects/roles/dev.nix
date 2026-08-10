{ den, ... }:
{
  # Extra dev tooling, opted into per host instead of following me onto every
  # machine. Same thinking as roles/gaming.nix - keeping the decision in a
  # role means no host name ever shows up under modules/users/.
  den.aspects.roles.dev.provides.to-users.includes = [
    den.aspects.apps.dev.code-cursor
    den.aspects.apps.dev.gemini
  ];
}
