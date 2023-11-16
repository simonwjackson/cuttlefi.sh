{
  description = "A Nix flake for the cuttlefish";

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
        cuttlefish = import ./cuttlefi.sh.nix {inherit pkgs;};
      in {
        packages."cuttlefi.sh" = cuttlefish;

        defaultPackage = cuttlefish;

        nixosModules.cuttlefish = import ./nixosModule.nix {
          inherit pkgs;
        };
      }
    );
}
