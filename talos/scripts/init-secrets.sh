#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
talos_dir="$(cd -- "${script_dir}/.." && pwd)"
repo_dir="$(cd -- "${talos_dir}/.." && pwd)"

output_relative="talos/secrets.sops.yaml"
output="${repo_dir}/${output_relative}"

required_commands=(
    talosctl
    yq
    sops
    openssl
    mktemp
)

for command_name in "${required_commands[@]}"; do
    if ! command -v "${command_name}" >/dev/null 2>&1; then
        printf 'Required command not found: %s\n' "${command_name}" >&2
        exit 1
    fi
done

if [[ -e "${output}" ]]; then
    printf 'Refusing to overwrite existing file: %s\n' "${output}" >&2
    exit 1
fi

workdir="$(mktemp -d)"
generated="${workdir}/talos-secrets.yaml"
plaintext="${workdir}/secrets.yaml"
encrypted="${workdir}/secrets.sops.yaml"

cleanup() {
    rm -rf "${workdir}"
}

trap cleanup EXIT INT TERM

printf 'Generating Talos PKI and tokens...\n'

talosctl gen secrets \
    --output-file "${generated}"

# These values are independent random 32-byte secrets.
export CLUSTER_SECRETBOXENCRYPTIONSECRET="$(
    openssl rand -base64 32 | tr -d '\r\n'
)"
export CLUSTER_ID="$(
    openssl rand -base64 32 | tr -d '\r\n'
)"
export CLUSTER_SECRET="$(
    openssl rand -base64 32 | tr -d '\r\n'
)"

# Convert the Talos secrets bundle into the context expected by MiniJinja.
yq eval '
{
  "secrets": {
    "MACHINE_CA_CRT": .certs.os.crt,
    "MACHINE_CA_KEY": .certs.os.key,
    "MACHINE_TOKEN": .trustdinfo.token,

    "CLUSTER_CA_CRT": .certs.k8s.crt,
    "CLUSTER_CA_KEY": .certs.k8s.key,

    "CLUSTER_AGGREGATORCA_CRT": .certs.k8saggregator.crt,
    "CLUSTER_AGGREGATORCA_KEY": .certs.k8saggregator.key,

    "CLUSTER_ETCD_CA_CRT": .certs.etcd.crt,
    "CLUSTER_ETCD_CA_KEY": .certs.etcd.key,

    "CLUSTER_SERVICEACCOUNT_KEY": .certs.k8sserviceaccount.key,

    "CLUSTER_SECRETBOXENCRYPTIONSECRET":
      strenv(CLUSTER_SECRETBOXENCRYPTIONSECRET),

    "CLUSTER_TOKEN": .secrets.bootstraptoken,
    "CLUSTER_ID": strenv(CLUSTER_ID),
    "CLUSTER_SECRET": strenv(CLUSTER_SECRET)
  }
}
' "${generated}" > "${plaintext}"

# Verify all 14 required values exist before encryption.
yq eval --exit-status '
  .secrets.MACHINE_CA_CRT and
  .secrets.MACHINE_CA_KEY and
  .secrets.MACHINE_TOKEN and
  .secrets.CLUSTER_CA_CRT and
  .secrets.CLUSTER_CA_KEY and
  .secrets.CLUSTER_AGGREGATORCA_CRT and
  .secrets.CLUSTER_AGGREGATORCA_KEY and
  .secrets.CLUSTER_ETCD_CA_CRT and
  .secrets.CLUSTER_ETCD_CA_KEY and
  .secrets.CLUSTER_SERVICEACCOUNT_KEY and
  .secrets.CLUSTER_SECRETBOXENCRYPTIONSECRET and
  .secrets.CLUSTER_TOKEN and
  .secrets.CLUSTER_ID and
  .secrets.CLUSTER_SECRET
' "${plaintext}" >/dev/null

printf 'Encrypting secrets with SOPS...\n'

cd "${repo_dir}"

sops encrypt \
    --filename-override "${output_relative}" \
    --output-type yaml \
    "${plaintext}" > "${encrypted}"

# Verify the encrypted result can be decrypted.
sops decrypt "${encrypted}" |
    yq eval --exit-status '.secrets | length == 14' - \
    >/dev/null

mv "${encrypted}" "${output}"

printf 'Created %s\n' "${output_relative}"