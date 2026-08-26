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

        blender-cuda = pkgs.blender.override {
          cudaSupport = true;
          cudaArches = [ "sm_50" ];
          openUsdSupport = false;
          spaceNavSupport = false;
          jackaudioSupport = false;
        };

        cli-packages = pkgs.symlinkJoin {
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
