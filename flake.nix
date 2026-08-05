{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{
    disko,
    flake-parts,
    nixpkgs,
    sops-nix,
    ...
  }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      flake.nixosConfigurations.k3s-master = nixpkgs.lib.nixosSystem {
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./nix/base.nix
          ./nix/host/master
          ./nix/module/garage.nix
          ./nix/module/k3s-master.nix
          ./nix/module/storage.nix
          ./nix/module/tailscale.nix
          ./nix/module/node-exporter.nix
        ];
        specialArgs = {
          hostName = "k3s-master";
        };
      };

      perSystem = { pkgs, ... }: {
        devShells.default = pkgs.mkShellNoCC {
          nativeBuildInputs = with pkgs; [
            nixos-rebuild
            kubefetch
            nix
            gum
            age
            sops
            go-task
            helmfile
            kubernetes-helm
            jq
            kustomize
            kubectl
            yq
            kubernetes-helmPlugins.helm-diff
            cilium-cli
            stern
            minijinja
          ];
        };
      };
    };
}
