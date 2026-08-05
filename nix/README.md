# NixOS services

## Garage

Garage runs directly on the NixOS host. Its metadata is stored under
`/var/lib/garage`, while object data and metadata snapshots are stored under
`/mnt/disk/garage`. The S3 API listens on port 3900 for LAN and Tailnet
clients.

Before the first rebuild, install the Age identity used by SOPS:

```shell
sudo install -d -m 0700 /var/lib/sops-nix
sudo install -m 0600 age.key /var/lib/sops-nix/key.txt
```

After the first rebuild, initialize the single-node layout:

```shell
sudo garage-manage status
sudo garage-manage layout assign --zone home --capacity <capacity> <node-id>
sudo garage-manage layout apply --version 1
```

Garage WebUI listens on port 3909 and is restricted to local connections.
Retrieve its generated password with SOPS, then connect through an SSH tunnel:

```shell
sops decrypt --extract '["data"]["garage_webui_password"]' nix/secrets/garage.sops.yaml
ssh -L 3909:127.0.0.1:3909 <garage-host>
```

Open `http://127.0.0.1:3909` and sign in as `admin`. The WebUI can then create
buckets and S3 access keys.
