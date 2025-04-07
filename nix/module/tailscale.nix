{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    extraSetFlags = [
      "--advertise-routes=192.168.1.0/24,192.168.1.96/27"
      "--advertise-exit-node=true"
    ];
    derper = {
      enable = true;
      domain = "derper.tuilakhanh.id.vn";
      openFirewall = true;
      verifyClients = true;
    };
  };
  services.nginx.enable = lib.mkForce false;

  services.caddy = {
    enable = true;
    virtualHosts."derper.tuilakhanh.id.vn".extraConfig = ''
      reverse_proxy 127.0.0.1:${toString config.services.tailscale.derper.port}
    '';
  };
}
