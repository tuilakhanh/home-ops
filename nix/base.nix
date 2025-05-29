{
  modulesPath,
  lib,
  pkgs,
  specialArgs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./networking.nix
  ];

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
      };
    };

    kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.core.rmem_max" = 7500000; # Cloudflared | QUIC
      "net.core.wmem_max" = 7500000; # Cloudflared | QUIC
    };
    kernelModules = [
      "ip6table_filter"
      "iptable_raw"
      "iptable_nat"
      "iptable_filter"
      "iptable_mangle"
      "ip_set"
      "ip_set_hash_ip"
      "xt_socket"
      "xt_mark"
      "xt_set"
      "cls_bpf"
      "sch_ingress"
      "crypto_user"
    ];
    blacklistedKernelModules = ["netfilter"];
  };

  time.timeZone = "Asia/Ho_Chi_Minh";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBJIbLDWXT1tVlvYvI9SXfEUWUBqDzQcZt5gh3x9psrc bacdau852@gmail.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXhQ7MGDLP+GXi+NtVd8vsQ58PGPKWVW0ODMZipEc6R khoanguyen@DESKTOP-L9174QP"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB76ZswJdQ0PstYXG1Syg0KmkzclsIT/bVB5GZikdVOr tiendat9tc@gmail.com"
  ];

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "incus-admin" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBJIbLDWXT1tVlvYvI9SXfEUWUBqDzQcZt5gh3x9psrc bacdau852@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXhQ7MGDLP+GXi+NtVd8vsQ58PGPKWVW0ODMZipEc6R khoanguyen@DESKTOP-L9174QP"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB76ZswJdQ0PstYXG1Syg0KmkzclsIT/bVB5GZikdVOr tiendat9tc@gmail.com"
    ];
  };

  nix = {
    settings = {
      trusted-users = [ "root" "@wheel" ];
      auto-optimise-store = true; # Optimise syslinks
      experimental-features = [ "nix-command" "flakes" ];
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    btop
    dig
    helmfile
    fluxcd
    kubernetes-helm
    kubernetes-helmPlugins.helm-diff
    git
    powertop
    intel-vaapi-driver
    nvtopPackages.intel
    wget
    unzip
    iperf3
    iotop
    gdu
    speedtest-go
    sysstat
    pipx
    smartmontools
    jdk11
    mkvtoolnix-cli
    unrar-free
    aria2
    toybox
  ];

  # virtualisation.containers.enable = true;
  # virtualisation = {
  #   podman = {
  #     enable = true;
  #     defaultNetwork.settings.dns_enabled = true;
  #   };
  # };


  services.openssh.enable = true;

  nix.package = lib.mkDefault pkgs.nixVersions.latest;

  system.stateVersion = "24.11";
}
