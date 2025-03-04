{
  pkgs,
  ...
}:
{
  virtualisation = {
    incus = {
      enable = true;
      ui.enable = true;
      package = pkgs.incus;
      preseed = {
        config = {
          "core.https_address" = "[::]:8443";
        };
        networks = [
          {
            config = {
              "ipv4.address" = "10.0.100.1/24";
              "ipv4.nat" = "true";
              "ipv6.address" = "auto";
            };
            name = "incusbr0";
            type = "bridge";
          }
        ];
        profiles = [
          {
            devices = {
              eth0 = {
                name = "eth0";
                type = "nic";
                nictype = "bridged";
                parent = "br0";
              };
              root = {
                path = "/";
                pool = "default";
                size = "10GiB";
                type = "disk";
              };
            };
            name = "default";
          }
          {
            devices = {
              eth0 = {
                name = "eth0";
                type = "nic";
                nictype = "bridged";
                parent = "br0";
              };
              root = {
                path = "/";
                pool = "default";
                size = "10GiB";
                type = "disk";
              };
            };
            name = "external";
          }
        ];
        storage_pools = [
          {
            config = {
              source = "/var/lib/incus/storage-pools/default";
            };
            driver = "btrfs";
            name = "default";
          }
        ];
      };
    };
  };
}
