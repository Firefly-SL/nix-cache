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
              ];
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
            ffmpeg-full
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
            obs-studio
            plezy
            affine
            rustdesk
            mpv
            flameshot
            hyprpicker
            xwayland-satellite
          ];
        };
      };
    };
}
