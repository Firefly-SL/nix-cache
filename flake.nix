{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages.${system}.blender-cuda = pkgs.callPackage ./blender/package.nix { };
    };
}
