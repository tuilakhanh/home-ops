{
lib,
specialArgs,
config,
...
}:

{
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
  networking.interfaces.dummy0.ipv4.addresses = [
    { address = "169.254.169.254"; prefixLength = 32; }
  ];

  networking.interfaces.dummy0.ipv6.addresses = [
    { address = "fd00:ec2::254"; prefixLength = 128; }
  ];
  systemd.services.k3s.serviceConfig.LimitNOFILE = lib.mkIf config.services.k3s.enable (lib.mkForce "infinity");
}
