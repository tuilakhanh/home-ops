{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    fuse
    mergerfs
  ];

  fileSystems = {
    "/mnt/wd16tb1" = {
      device = "/dev/disk/by-uuid/7ca15b8e-9bcc-437a-b33c-f425a8e26036";
      fsType = "btrfs";
      options = [
        "noatime"
        "space_cache=v2"
        "autodefrag"
        "flushoncommit"
        "nofail"
      ];
    };
    "/mnt/wd14tb1" = {
      device = "/dev/disk/by-uuid/86277fcd-12da-42b1-b8f0-efe6aa5473e4";
      fsType = "ext4";
      options = [
        "defaults"
        "noatime"
        "nofail"
      ];
    };
    "/mnt/disk" = {
      device = "/mnt/wd14tb1:/mnt/wd16tb1";
      fsType = "fuse.mergerfs";
      options = [
        "allow_other"
        "use_ino"
        "cache.files=partial"
        "dropcacheonclose=true"
        "category.create=mfs"
      ];
      noCheck = true;
    };
  };

  services.nfs.server = {
    enable = true;
    exports = ''
      /mnt/disk 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash) 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash)
    '';
  };
}
