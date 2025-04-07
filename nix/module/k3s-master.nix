{
lib,
specialArgs,
config,
# k0s,
...
}:

{
  # nixpkgs.overlays = [
  #   k0s.overlays.default
  # ];

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = [
      "--flannel-backend=none"
      "--disable-network-policy"
      "--disable-kube-proxy"
      "--disable metrics-server"
      "--disable servicelb"
      "--disable traefik"
      "--disable coredns"
      "--disable local-storage"
      "--cluster-cidr=10.69.0.0/16"
      "--service-cidr=10.96.0.0/16"
      "--node-label intel.feature.node.kubernetes.io/gpu=true"
    ];
  };
  systemd.services.k3s.serviceConfig.LimitNOFILE = lib.mkIf config.services.k3s.enable (lib.mkForce "infinity");
  systemd.services.k3s.serviceConfig.LimitNOFILESoft = lib.mkIf config.services.k3s.enable (lib.mkForce "infinity");

  # services.k0s = {
  #   enable = true;
  #   role = "single";
  #   isLeader = true;
  #   spec = {
  #     api = {
  #       address = "192.168.1.36";
  #       sans = [
  #         "192.168.1.36"
  #         "100.85.148.46"
  #         "k3s-master"
  #       ];
  #     };
  #     network = {
  #       provider = "custom";
  #       kubeProxy = {
  #         disabled = true;
  #       };
  #     };
  #   };
  # };

  # virtualisation.containerd = {
  #   enable = true;
  # };

  # environment = {
  #   systemPackages = [
  #     k0s.packages.x86_64-linux.k0s
  #   ];
  # };
}
