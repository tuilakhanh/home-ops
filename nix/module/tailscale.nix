{
  pkgs,
  ...
}:
{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    extraUpFlags = [
      "--advertise-routes=192.168.1.0/24"
    ];
  };
}
