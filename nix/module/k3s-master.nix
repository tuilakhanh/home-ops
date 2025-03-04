{
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
      "--cluster-cidr=10.69.0.0/16"
      "--service-cidr=10.96.0.0/16"
      "--node-label intel.feature.node.kubernetes.io/gpu=true"
    ];
  };
}
