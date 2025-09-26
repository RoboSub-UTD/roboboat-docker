{
  description = "A quick flake for Dockerfile development";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
    in
    {
      devShells."${system}".default =
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in
        pkgs.mkShell {
          # create an environment with nodejs_18, pnpm, and yarn
          packages = with pkgs; [
            harper
            marksman
            docker-compose
            docker-client
            docker-buildx
            dockerfile-language-server-nodejs
            docker-compose-language-service
            yaml-language-server
            lazygit
          ];
          shellHook = ''
            mkdir -p "$HOME/.docker/cli-plugins"
            ln -sf "$(which docker-buildx)" "$HOME/.docker/cli-plugins/docker-buildx"
          '';
          # Environment variables
          COMPOSE_BAKE = true;
          DOCKER_BUILDKIT = true;
          COMPOSE_DOCKER_CLI_BUILD = true;
        };
    };
}
