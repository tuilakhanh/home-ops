{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = {
    self,
    disko,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      flake = {
        # nixosConfigurations.k3s-master = inputs.nixpkgs.lib.nixosSystem {
        #   modules = [
        #     disko.nixosModules.disko
        #     ./base.nix
        #     ./hardware-configuration.nix
        #     ./k3s-master.nix
        #     ./networking.nix
        #     ./incus.nix
        #   ];
        #   specialArgs = {
        #     inherit inputs;
        #     hostName = "k3s-master";
        #   };
        # };
      };
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        devShells.default = pkgs.mkShell {
          shellHook = ''
            FLAKE_ROOT="$PWD"
            export KUBERNETES_DIR="$FLAKE_ROOT/kubernetes"
            export KUBECONFIG="$FLAKE_ROOT/kubeconfig"
            export SOPS_AGE_KEY_FILE="$FLAKE_ROOT/age.key"
          '';

          nativeBuildInputs = with pkgs; [
            fluxctl
            kube-capacity
            nixos-rebuild
            kubefetch
            nix
            gum
            cloudflared
            age
            sops
            go-task
            helmfile
            kubernetes-helm
            jq
            kustomize
            kubectl
            yq
            kubeconform
            kubernetes-helmPlugins.helm-diff
            cilium-cli
            (python3.withPackages (ps: with ps; [
              cloudflare
              dnspython
              email-validator
              makejinja
              netaddr
              ntplib
            ]))
          ];
        };
      };
    };
}
