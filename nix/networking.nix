{
  hostName,
  lib,
  ...
}:
{
  networking = {
    inherit hostName;
    nameservers = [
      "1.1.1.1#one.one.one.one"
      "1.0.0.1#one.one.one.one"
    ];
    networkmanager = {
      enable = true;
      dns = lib.mkForce "none";
      ensureProfiles.profiles.lan-static = {
        connection = {
          id = "lan-static";
          type = "ethernet";
          autoconnect = "true";
          autoconnect-priority = "100";
        };
        ethernet.mac-address = "00:E0:4C:68:00:3F";
        ipv4 = {
          address1 = "192.168.1.36/24,192.168.1.1";
          method = "manual";
        };
        ipv6.method = "auto";
      };
    };
    nat.enable = false;
    firewall.enable = false;
    dhcpcd.extraConfig = "nohook resolv.conf";
  };

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      Domains = "~.";
      LLMNR = "true";
      FallbackDns = [
        "1.1.1.1"
        "2606:4700:4700::1111"
        "8.8.8.8"
        "2001:4860:4860::8844"
      ];
    };
  };
}
