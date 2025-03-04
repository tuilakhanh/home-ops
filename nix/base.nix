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
    ];
  };

  time.timeZone = "Asia/Ho_Chi_Minh";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBJIbLDWXT1tVlvYvI9SXfEUWUBqDzQcZt5gh3x9psrc bacdau852@gmail.com"
  ];

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "incus-admin" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBJIbLDWXT1tVlvYvI9SXfEUWUBqDzQcZt5gh3x9psrc bacdau852@gmail.com"
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
    iptables
    powertop
    intel-vaapi-driver
    nvtopPackages.intel
    stress-ng
    s-tui
    wget
    unzip
    iperf3
    iotop
  ];

  services.openssh.enable = true;

  system.stateVersion = "24.11";
}
