{config, pkgs, ...}:
{
  services.prometheus.exporters.node = {
    enable = true;
    port = 9000;
    enabledCollectors = [ "systemd" ];
    extraFlags = [ "--collector.ethtool" "--collector.softirqs" "--collector.tcpstat" ];
  };
  services.prometheus.exporters.smartctl.enable = true;
  services.prometheus.exporters.process.enable = true;
}
