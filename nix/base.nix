{
  modulesPath,
  lib,
  pkgs,
  ...
}:
let
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBJIbLDWXT1tVlvYvI9SXfEUWUBqDzQcZt5gh3x9psrc bacdau852@gmail.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXhQ7MGDLP+GXi+NtVd8vsQ58PGPKWVW0ODMZipEc6R khoanguyen@DESKTOP-L9174QP"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB76ZswJdQ0PstYXG1Syg0KmkzclsIT/bVB5GZikdVOr tiendat9tc@gmail.com"
  ];
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./networking.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    kernelPackages = pkgs.linuxPackages_latest;
    kernel.sysctl = {
      "fs.inotify.max_user_instances" = 8192;
      "fs.inotify.max_user_watches" = 1048576;
      "net.core.default_qdisc" = "fq";
      "net.core.rmem_max" = 67108864;
      "net.core.wmem_max" = 67108864;
      "net.ipv4.ip_forward" = 1;
      "net.ipv4.neigh.default.gc_thresh1" = 4096;
      "net.ipv4.neigh.default.gc_thresh2" = 8192;
      "net.ipv4.neigh.default.gc_thresh3" = 16384;
      "net.ipv4.ping_group_range" = "0 2147483647";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_mtu_probing" = 1;
      "net.ipv4.tcp_notsent_lowat" = 131072;
      "net.ipv4.tcp_rmem" = "4096 87380 33554432";
      "net.ipv4.tcp_slow_start_after_idle" = 0;
      "net.ipv4.tcp_window_scaling" = 1;
      "net.ipv4.tcp_wmem" = "4096 65536 33554432";
      "net.ipv6.conf.all.forwarding" = 1;
      "sunrpc.tcp_max_slot_table_entries" = 128;
      "sunrpc.tcp_slot_table_entries" = 128;
      "user.max_user_namespaces" = 11255;
    };
    kernelModules = [
      "xt_socket"
      "xt_mark"
      "xt_set"
      "cls_bpf"
      "sch_ingress"
      "crypto_user"
    ];
    blacklistedKernelModules = [ "iwlwifi" ];
  };

  zramSwap.enable = true;

  time.timeZone = "Asia/Ho_Chi_Minh";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users = {
    root.openssh.authorizedKeys.keys = authorizedKeys;
    nixos = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = authorizedKeys;
    };
  };

  nix = {
    package = lib.mkDefault pkgs.nixVersions.latest;
    settings = {
      trusted-users = [ "root" "@wheel" ];
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    btop
    kubernetes-helm
    git
    powertop
    intel-vaapi-driver
    nvtopPackages.intel
    wget
    unzip
    iperf3
    iotop
    gdu
    cfspeedtest
    smartmontools
    mkvtoolnix-cli
    unrar-free
    aria2
    toybox
    fastfetch
    podman-compose
    linuxPackages.cpupower
    prometheus-process-exporter
  ];

  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  services = {
    openssh.enable = true;
    scx = {
      enable = true;
      scheduler = "scx_lavd";
    };
  };

  system.stateVersion = "25.05";
}
