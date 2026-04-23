{
  flake.modules.homeManager.pc =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        nh
        nix-diff
        nix-output-monitor
        nixd
        nixfmt
      ];
    };
}
