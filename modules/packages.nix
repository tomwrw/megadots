{
  # Baseline CLI tools expected on any host — including headless/remote.
  # Anything interactive or workstation-oriented belongs in the `pc` tag.
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        fd
        jq
        ripgrep
        unzip
      ];
    };

  # Workstation-only tooling: SOPS/age handling, secure-boot tooling, etc.
  flake.modules.nixos.pc =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        age
        fastfetch
        fzf
        just
        pciutils
        sbctl
        sops
        ssh-to-age
      ];
    };
}
