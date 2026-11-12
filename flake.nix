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
      packages.${system}.blender-cuda =
        (pkgs.callPackage ./blender/package.nix {
          cudaSupport = true;
          openUsdSupport = false;
          jackaudioSupport = false;
          oneapiSupport = false;
          rocmSupport = false;
        }).overrideAttrs
          (oldAttrs: {
            cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
              "-DWITH_CYCLES_DEVICE_CUDA=ON"
              "-DWITH_CYCLES_CUDA_BINARIES=ON"
              "-DWITH_CYCLES_DEVICE_HIP=OFF"
              "-DWITH_CYCLES_HIP_BINARIES=OFF"
              "-DWITH_CYCLES_DEVICE_ONEAPI=OFF"
              "-DWITH_CYCLES_ONEAPI_BINARIES=OFF"
              "-DWITH_CYCLES_DEVICE_OPTIX=OFF"
              "-DCYCLES_CUDA_BINARIES_ARCH=sm_50"
            ];
          });
    };
}
