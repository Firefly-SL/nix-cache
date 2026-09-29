{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      nixpkgs,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages.${system} = {

        kernel-main-machine = pkgs.linuxPackages_latest.kernel.override {
          structuredExtraConfig = with pkgs.lib.kernel; {
            X86_NATIVE_CPU = yes;

            HZ_250 = no;
            HZ_1000 = yes;
            HZ = freeform "1000";

            CPU_SUP_AMD = pkgs.lib.mkForce no;
            CPU_SUP_CENTAUR = pkgs.lib.mkForce no;
            CPU_SUP_ZHAOXIN = pkgs.lib.mkForce no;
            CPU_SUP_HYGON = pkgs.lib.mkForce no;

            HYPERVISOR_GUEST = pkgs.lib.mkForce no;

            DEBUG_INFO = pkgs.lib.mkForce no;
            DEBUG_KERNEL = pkgs.lib.mkForce no;
            KGDB = pkgs.lib.mkForce no;
            FTRACE = pkgs.lib.mkForce no;
          };
        };

        blender-cuda =
          (pkgs.blender.override {
            cudaSupport = true;
            openUsdSupport = false;
            jackaudioSupport = false;
          }).overrideAttrs
            (oldAttrs: {
              cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
                "-DWITH_CYCLES_DEVICE_HIP=OFF"
                "-DWITH_CYCLES_HIP_BINARIES=OFF"
                "-DWITH_CYCLES_DEVICE_ONEAPI=OFF"
                "-DWITH_CYCLES_ONEAPI_BINARIES=OFF"
                "-DWITH_CYCLES_DEVICE_OPTIX=OFF"
                "-DCYCLES_CUDA_BINARIES_ARCH=sm_50"
              ];

              postPatch = (oldAttrs.postPatch or "") + ''
                cp ${./assets/blender/splash.png} release/datafiles/splash.png
                cp ${./assets/blender/startup.blend} release/datafiles/startup.blend
              '';
            });

        cli-packages = pkgs.symlinkJoin {
          name = "cli-packages";
          paths = with pkgs; [
            cht-sh
            neovim
            zoxide
            tmux
            cloudflared
            wiremix
            btop
            fzf
            bat
            lsd
            ripgrep
            fd
            ffmpeg
            pywal16
            awww
            fastfetch
          ];
        };

        dev-packages = pkgs.symlinkJoin {
          name = "dev-packages";
          paths = with pkgs; [
            bun
            basedpyright
            ruff
            lua-language-server
            stylua
            bash-language-server
            vscode-langservers-extracted
            emmet-ls
            tree-sitter
            lazygit
          ];
        };

        misc = pkgs.symlinkJoin {
          name = "misc-packages";
          paths = with pkgs; [
            ly
            niri
            (obs-studio.override {
              browserSupport = false;
              scriptingSupport = false;
            })
            plezy
            affine
            mpv
            flameshot
            hyprpicker
            xwayland-satellite
          ];
        };
      };
    };
}
