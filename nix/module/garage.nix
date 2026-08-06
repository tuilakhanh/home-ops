{
  config,
  lib,
  pkgs,
  ...
}:
let
  garageWebui = pkgs.callPackage ../package/garage-webui.nix { };
in
{
  sops = {
    defaultSopsFile = ../secrets/garage.sops.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets = {
      garage-rpc-secret = {
        key = "data/garage_rpc_secret";
        owner = "garage";
        restartUnits = [ "garage.service" ];
      };
      garage-admin-token = {
        key = "data/garage_admin_token";
        owner = "garage";
        mode = "0400";
        restartUnits = [ "garage.service" ];
      };
      garage-webui-admin-token = {
        key = "data/garage_admin_token";
        owner = "garage-webui";
        mode = "0400";
        restartUnits = [ "garage-webui.service" ];
      };
      garage-metrics-token = {
        key = "data/garage_metrics_token";
        owner = "garage";
        restartUnits = [ "garage.service" ];
      };
      garage-webui-password = {
        key = "data/garage_webui_password";
        owner = "garage-webui";
        restartUnits = [ "garage-webui.service" ];
      };
    };
  };

  users = {
    groups = {
      garage = { };
      garage-webui = { };
    };
    users = {
      garage = {
        isSystemUser = true;
        group = "garage";
      };
      garage-webui = {
        isSystemUser = true;
        group = "garage-webui";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /mnt/disk/garage 0750 garage garage -"
    "d /mnt/disk/garage/data 0750 garage garage -"
    "d /mnt/disk/garage/snapshots 0750 garage garage -"
  ];

  services.garage = {
    enable = true;
    package = pkgs.garage_2;
    settings = {
      metadata_dir = "/var/lib/garage/meta";
      metadata_snapshots_dir = "/mnt/disk/garage/snapshots";
      data_dir = "/mnt/disk/garage/data";
      db_engine = "sqlite";
      metadata_fsync = true;
      data_fsync = true;
      replication_factor = 1;
      consistency_mode = "consistent";

      rpc_bind_addr = "127.0.0.1:3901";
      rpc_public_addr = "127.0.0.1:3901";
      rpc_secret_file = config.sops.secrets.garage-rpc-secret.path;

      s3_api = {
        api_bind_addr = "0.0.0.0:3900";
        s3_region = "garage";
      };

      admin = {
        api_bind_addr = "127.0.0.1:3903";
        admin_token_file = config.sops.secrets.garage-admin-token.path;
        metrics_token_file = config.sops.secrets.garage-metrics-token.path;
        metrics_require_token = true;
      };
    };
  };

  systemd.services = {
    garage = {
      after = [
        "mnt-wd14tb1.mount"
        "mnt-wd16tb1.mount"
        "mnt-disk.mount"
      ];
      requires = [
        "mnt-wd14tb1.mount"
        "mnt-wd16tb1.mount"
        "mnt-disk.mount"
      ];
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "garage";
        Group = "garage";
        ReadWritePaths = [ "/mnt/disk/garage" ];
        IPAddressAllow = [
          "localhost"
          "192.168.1.0/24"
          "10.69.0.0/16"
          "100.64.0.0/10"
        ];
        IPAddressDeny = "any";
      };
    };

    garage-webui = {
      description = "Garage Web UI";
      wantedBy = [ "multi-user.target" ];
      after = [ "garage.service" ];
      requires = [ "garage.service" ];
      environment = {
        API_BASE_URL = "http://127.0.0.1:3903";
        PORT = "3909";
        S3_ENDPOINT_URL = "http://127.0.0.1:3900";
        S3_REGION = "garage";
      };
      script = ''
        admin_key="$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.garage-webui-admin-token.path})"
        password="$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.garage-webui-password.path})"
        password_hash="$(printf '%s\n' "$password" | ${lib.getExe' pkgs.apacheHttpd "htpasswd"} -niBC 12 admin | ${pkgs.coreutils}/bin/cut -d: -f2)"
        unset password

        export API_ADMIN_KEY="$admin_key"
        export AUTH_USER_PASS="admin:$password_hash"
        exec ${lib.getExe garageWebui}
      '';
      serviceConfig = {
        User = "garage-webui";
        Group = "garage-webui";
        Restart = "on-failure";
        RestartSec = 5;

        IPAddressAllow = [
          "localhost"
          "192.168.1.0/24"
        ];
        IPAddressDeny = "any";
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
      };
    };
  };
}
