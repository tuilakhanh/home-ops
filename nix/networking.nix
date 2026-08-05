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
    networkmanager.enable = true;
    nat.enable = false;
    firewall.enable = false;
    dhcpcd.extraConfig = "nohook resolv.conf";
    networkmanager.dns = lib.mkForce "none";
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
