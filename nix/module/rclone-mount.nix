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
  ];
  fileSystems."/mnt/media" = {
    device = "media:";
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
      "vfs-write-back=1h"
      "vfs-cache-max-age=2h"
      "tpslimit=12"
      "tpslimit-burst=0"
      "drive-chunk-size=128M"
      "args2env"
      "config=/root/.config/rclone/rclone.conf"
    ];
  };

  fileSystems."/mnt/disk" = {
    device = "/dev/disk/by-uuid/ed18f4a2-aa69-4b74-8714-d2fe3daa3ef9";
    fsType = "btrfs";
  };
}
