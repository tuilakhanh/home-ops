{
  modulesPath,
  lib,
  pkgs,
  specialArgs,
  ...
}:
{
  networking = {
    hostName = specialArgs.hostName;
    # nftables.enable = true;
    # firewall = {
    #   allowedTCPPorts = [
    #     8443
    #     53
    #     67
    #     6443
    #   ];
    #   allowedUDPPorts = [
    #     53
    #     67
    #   ];
    # };
    firewall.enable = false;
    # useDHCP = false;
  };

  # systemd.network = {
  #   enable = true;
  #   netdevs = {
  #     "20-br0" = {
  #       netdevConfig = {
  #         Name = "br0";
  #         Kind = "bridge";
  #         MACAddress = "5e:1d:f3:18:e1:a5";
  #       };
  #     };
  #   };

  #   networks = {
  #     "20-br0" = {
  #       matchConfig.Name = "br0";
  #       networkConfig = {
  #         Description = "configure br0 to get IP from DHCP server";
  #         DHCP = true;
  #       };
  #       linkConfig.RequiredForOnline = "carrier";
  #     };
  #     "20-br0-en" = {
  #       matchConfig.Name = "en*";
  #       networkConfig = {
  #         Description = "add en* interfaces to become member of br0 bridge";
  #         Bridge = "br0";
  #       };
  #       linkConfig.RequiredForOnline = "enslaved";
  #     };
  #   };
  # };
}
