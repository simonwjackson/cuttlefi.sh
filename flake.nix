{
  description = "A Nix flake for the podcast-cli-app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05"; # Adjust the channel as needed
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        podcast-cli-app = import ./podcast-cli-app.nix {inherit pkgs;};
      in {
        packages.podcast-cli-app = podcast-cli-app;

        defaultPackage = self.packages.${system}.podcast-cli-app;

        nixosModules.podcast-cli-app = import ./nixosModule.nix {
          inherit pkgs;
        };
      }
    );
}
