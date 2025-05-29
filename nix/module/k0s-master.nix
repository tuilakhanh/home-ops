{ lib, pkgs, ... }:
let
  pname = "k0s";

  owner = "k0sproject";
  repo = pname;
  description = "k0s - The Zero Friction Kubernetes";

  version = "1.32.4+k0s.0";
  hash = "sha256-fxXYT5Ddw6F+XuW6y1M7C4iZuPSip+eP627r+Zm1ly8=";

  k0s = pkgs.stdenv.mkDerivation {
    name = "${pname}-${version}";
    src = pkgs.fetchurl {
      url = "https://github.com/${owner}/${repo}/releases/download/v${version}/${repo}-v${version}-amd64";
      inherit hash;
    };
    phases = [ "installPhase" ];
    installPhase = ''
      install -m 555 -D -- "$src" "$out"/bin/'${pname}'
    '';
    # Metadata required for a real package
    meta = with lib; {
      inherit description;
      license = licenses.asl20;
      homepage = "https://k0sproject.io";
      platforms = [ "x86_64-linux" ]; # ARM 32/64 binary releases also available.
    };
  };

  # Some minimal sample config
  k0sConfig = pkgs.writeText "${pname}.json" (builtins.toJSON {
    apiVersion = "k0s.k0sproject.io/v1beta1";
    kind = "ClusterConfig";
    metadata.name = pname;
    spec = {
      api = {
        address = "192.168.1.36";
        sans = [
          "192.168.1.36"
          "k3s-master"
          "100.85.148.46"
        ];
      };
      network = {
        provider = "custom";
        kubeProxy = {
          disabled = true;
        };
        podCIDR = "10.69.0.0/16";
        serviceCIDR = "10.96.0.0/16";
      };
      storage = {
        type = "kine";
      };
    };
  });
in
{
  # If k0s should be in the PATH:
  environment.systemPackages = [ k0s ];

  systemd.services.k0scontroller = {
    inherit description;
    documentation = [ "https://docs.k0sproject.io" ];
    path = with pkgs; [
      kmod
      util-linux
      mount
    ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    startLimitIntervalSec = 5;
    startLimitBurst = 10;
    serviceConfig = {
      RestartSec = 120;
      Delegate = "yes";
      KillMode = "process";
      LimitCORE = "infinity";
      TasksMax = "infinity";
      TimeoutStartSec = 0;
      LimitNOFILE = "infinity";
      Restart = "always";
      ExecStart = "${k0s}/bin/k0s controller --config=${k0sConfig} --data-dir=/var/lib/k0s --single=true --disable-components=metrics-server,coredns,kube-proxy";
    };
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
}
