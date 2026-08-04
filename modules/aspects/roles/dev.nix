{ den, ... }:
{
  # Extra developer tooling, opted into per host rather than carried by every
  # machine the user exists on. Same reasoning as roles/gaming.nix: keeping the
  # decision in a role means no host name ever appears under modules/users/.
  den.aspects.roles.dev.provides.to-users.includes = [
    den.aspects.apps.dev.code-cursor
    den.aspects.apps.dev.gemini
  ];
}
