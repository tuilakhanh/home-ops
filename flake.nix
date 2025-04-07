{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";

    k0s = {
      url = "github:johbo/k0s-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    disko,
    flake-parts,
    k0s,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      flake = {
        nixosConfigurations.k3s-master = inputs.nixpkgs.lib.nixosSystem {
          modules = [
            disko.nixosModules.disko
            k0s.nixosModules.default
            ./nix/base.nix
            ./nix/host/master
            # ./nix/module/incus.nix
            # ./nix/module/k3s-master.nix
            ./nix/module/k0s-master.nix
            ./nix/module/rclone-mount.nix
            ./nix/module/tailscale.nix
            ./nix/module/node-exporter.nix
          ];
          specialArgs = {
            inherit inputs;
            inherit k0s;
            hostName = "k3s-master";
          };
        };
      };
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        devShells.default = pkgs.mkShell {
          shellHook = ''
            FLAKE_ROOT="$PWD"
            export ROOT_DIR="$FLAKE_ROOT"
            export BOOTSTRAP_DIR="$FLAKE_ROOT/bootstrap"
            export SCRIPTS_DIR="$FLAKE_ROOT/scripts"
            export KUBERNETES_DIR="$FLAKE_ROOT/kubernetes"
            export KUBECONFIG="$FLAKE_ROOT/kubeconfig"
            export SOPS_AGE_KEY_FILE="$FLAKE_ROOT/age.key"
          '';

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
            k0sctl
          ];
        };
      };
    };
}
