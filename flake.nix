{
  description = "A quick flake for Dockerfile development";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nix-conf = {
      url = "github:wentasah/nix-conf";
      flake = false;
    };
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
          # Import the veridian package from nix-conf
          veridian = pkgs.callPackage "${inputs.nix-conf}/pkgs/veridian/default.nix" { };
        in
        pkgs.mkShell {
          # create an environment with nodejs_18, pnpm, and yarn
          packages = with pkgs; [
            dockerfile-language-server-nodejs
            docker-compose-language-service
            yaml-language-server
            lazygit
          ];

          shellHook = ''
            echo "You're in the SystemVerilog development shell using the 'iverilog' simulator"
          '';
        };
    };
}

