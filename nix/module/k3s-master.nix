{
  config,
  lib,
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
      "--kubelet-arg=eviction-hard=memory.available<100Mi,nodefs.available<5%"
      "--kubelet-arg=eviction-minimum-reclaim=memory.available=100Mi,nodefs.available=1Gi"
      "--kubelet-arg=feature-gates=MutatingAdmissionPolicy=true"
      "--kube-apiserver-arg=runtime-config=admissionregistration.k8s.io/v1beta1=true"
    ];
  };

  systemd.services.k3s.serviceConfig.LimitNOFILE = lib.mkIf config.services.k3s.enable (lib.mkForce "infinity");
}
