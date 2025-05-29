{
lib,
specialArgs,
config,
# k0s,
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
  systemd.user.extraConfig = "DefaultLimitNOFILE=32000";
  boot = {
    kernel.sysctl = {
      "fs.inotify.max_user_instances" = 8192;
      "fs.inotify.max_user_watches" = 524288;
    };
    kernelModules = [
      # IPVS for kube-vip
      "ip_vs"
      "ip_vs_rr"

      # Wireguard for VPN
      "tun"
      "wireguard"
    ];
  };
  systemd.services.k3s.serviceConfig.LimitNOFILE = lib.mkIf config.services.k3s.enable (lib.mkForce "infinity");
  systemd.services.k3s.serviceConfig.LimitNOFILESoft = lib.mkIf config.services.k3s.enable (lib.mkForce "infinity");
}
