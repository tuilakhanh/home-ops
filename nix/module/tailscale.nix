{
  pkgs,
  ...
}:
{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    extraUpFlags = [
      "--advertise-routes=192.168.2.0/24"
    ];
  };
}
