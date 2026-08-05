{ ... }:
{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    extraSetFlags = [
      "--advertise-routes=192.168.1.0/24,192.168.1.96/27"
      "--advertise-exit-node=true"
    ];
  };
}
