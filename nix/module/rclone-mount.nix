{
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    rclone
    fuse
    mergerfs
  ];
  # fileSystems."/mnt/media" = {
  #   device = "media:";
  #   fsType = "rclone";
  #   options = [
  #     "nodev"
  #     "nofail"
  #     "read-only"
  #     "allow_other"
  #     "dir-cache-time=2h"
  #     "uid=1000"
  #     "gid=1000"
  #     "umask=002"
  #     "vfs-cache-mode=full"
  #     "vfs-cache-max-size=30G"
  #     "vfs-fast-fingerprint"
  #     "vfs-write-back=1h"
  #     "vfs-cache-max-age=2h"
  #     "tpslimit=8"
  #     "tpslimit-burst=16"
  #     "drive-chunk-size=128M"
  #     "args2env"
  #     "config=/root/.config/rclone/rclone.conf"
  #   ];
  # };

  fileSystems."/mnt/network" = {
    device = "s3:";
    fsType = "rclone";
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "dir-cache-time=2h"
      "uid=1000"
      "gid=1000"
      "umask=002"
      "vfs-cache-mode=full"
      "vfs-cache-max-size=10G"
      "vfs-fast-fingerprint"
      # "vfs-write-back=30m"
      "vfs-cache-max-age=1h"
      "tpslimit=8"
      "tpslimit-burst=16"
      "args2env"
      "config=/root/.config/rclone/rclone.conf"
    ];
  };

  fileSystems = {
    "/mnt/wd14tb1" = {
      device = "/dev/disk/by-uuid/ec508d89-e374-4db4-bd42-20954e43ddcd";
      fsType = "btrfs";
      options = [ "defaults" "nofail" ];
    };
    "/mnt/wd1tb" = {
      device = "/dev/disk/by-uuid/7a5d6051-e222-4bcb-bb23-3dc17417940a";
      fsType = "btrfs";
      options = [ "defaults" "nofail" ];
    };
    "/mnt/disk" = {
      device = "/mnt/wd14tb1:/mnt/wd1tb";
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
}
