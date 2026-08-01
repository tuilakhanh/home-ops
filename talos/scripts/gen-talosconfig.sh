#!/usr/bin/env bash
set -euo pipefail

# Ensure temporary secrets and talosconfig are owner-readable only.
umask 077

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
talos_dir="$(cd -- "${script_dir}/.." && pwd)"
repo_dir="$(cd -- "${talos_dir}/.." && pwd)"

secrets_file="${repo_dir}/talos/secrets.sops.yaml"
output="${repo_dir}/talosconfig"

cluster_name=""
force=false

declare -a endpoints=()
declare -a nodes=()

usage() {
    cat <<'EOF'
Usage:
  gen-talosconfig.sh \
    --cluster-name <name> \
    --endpoint <control-plane-address> \
    [--endpoint <control-plane-address> ...] \
    --node <node-address> \
    [--node <node-address> ...] \
    [--force]

Example:
  gen-talosconfig.sh \
    --cluster-name home \
    --endpoint 192.168.1.11 \
    --endpoint 192.168.1.12 \
    --endpoint 192.168.1.13 \
    --node 192.168.1.11 \
    --node 192.168.1.12 \
    --node 192.168.1.13 \
    --node 192.168.1.21

Options:
  --cluster-name NAME    Talosconfig context/cluster name
  --endpoint ADDRESS    Talos API endpoint; repeat as needed
  --node ADDRESS        Default target node; repeat as needed
  --force               Replace an existing talosconfig
  -h, --help            Show this help
EOF
}

while (($# > 0)); do
    case "$1" in
        --cluster-name)
            [[ $# -ge 2 ]] || {
                printf 'Missing value for %s\n' "$1" >&2
                exit 2
            }

            cluster_name="$2"
            shift 2
            ;;

        --endpoint)
            [[ $# -ge 2 ]] || {
                printf 'Missing value for %s\n' "$1" >&2
                exit 2
            }

            endpoints+=("$2")
            shift 2
            ;;

        --node)
            [[ $# -ge 2 ]] || {
                printf 'Missing value for %s\n' "$1" >&2
                exit 2
            }

            nodes+=("$2")
            shift 2
            ;;

        --force)
            force=true
            shift
            ;;

        -h|--help)
            usage
            exit 0
            ;;

        *)
            printf 'Unknown argument: %s\n\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

required_commands=(
    talosctl
    yq
    sops
    mktemp
)

for command_name in "${required_commands[@]}"; do
    if ! command -v "${command_name}" >/dev/null 2>&1; then
        printf 'Required command not found: %s\n' "${command_name}" >&2
        exit 1
    fi
done

if [[ -z "${cluster_name}" ]]; then
    printf 'Missing required option: --cluster-name\n' >&2
    exit 2
fi

if ((${#endpoints[@]} == 0)); then
    printf 'At least one --endpoint is required.\n' >&2
    exit 2
fi

if ((${#nodes[@]} == 0)); then
    printf 'At least one --node is required.\n' >&2
    exit 2
fi

if [[ ! -f "${secrets_file}" ]]; then
    printf 'Secrets file not found: %s\n' "${secrets_file}" >&2
    exit 1
fi

if [[ -e "${output}" && "${force}" != true ]]; then
    printf 'Refusing to overwrite existing file: %s\n' "${output}" >&2
    printf 'Use --force to replace it.\n' >&2
    exit 1
fi

workdir="$(mktemp -d)"
plaintext="${workdir}/secrets.yaml"
bundle="${workdir}/talos-secrets.yaml"
generated_config="${workdir}/talosconfig"

cleanup() {
    rm -rf "${workdir}"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

printf 'Decrypting %s...\n' "${secrets_file#"${repo_dir}/"}"

sops decrypt "${secrets_file}" > "${plaintext}"

printf 'Reconstructing Talos secrets bundle...\n'

yq eval '
{
  "cluster": {
    "id": .secrets.CLUSTER_ID,
    "secret": .secrets.CLUSTER_SECRET
  },

  "secrets": {
    "bootstraptoken":
      .secrets.CLUSTER_TOKEN,

    "secretboxencryptionsecret":
      .secrets.CLUSTER_SECRETBOXENCRYPTIONSECRET
  },

  "trustdinfo": {
    "token": .secrets.MACHINE_TOKEN
  },

  "certs": {
    "etcd": {
      "crt": .secrets.CLUSTER_ETCD_CA_CRT,
      "key": .secrets.CLUSTER_ETCD_CA_KEY
    },

    "k8s": {
      "crt": .secrets.CLUSTER_CA_CRT,
      "key": .secrets.CLUSTER_CA_KEY
    },

    "k8saggregator": {
      "crt": .secrets.CLUSTER_AGGREGATORCA_CRT,
      "key": .secrets.CLUSTER_AGGREGATORCA_KEY
    },

    "k8sserviceaccount": {
      "key": .secrets.CLUSTER_SERVICEACCOUNT_KEY
    },

    "os": {
      "crt": .secrets.MACHINE_CA_CRT,
      "key": .secrets.MACHINE_CA_KEY
    }
  }
}
' "${plaintext}" > "${bundle}"

# Validate all fields required by a Talos secrets bundle.
yq eval --exit-status '
  .cluster.id and
  .cluster.secret and

  .secrets.bootstraptoken and
  .secrets.secretboxencryptionsecret and

  .trustdinfo.token and

  .certs.etcd.crt and
  .certs.etcd.key and

  .certs.k8s.crt and
  .certs.k8s.key and

  .certs.k8saggregator.crt and
  .certs.k8saggregator.key and

  .certs.k8sserviceaccount.key and

  .certs.os.crt and
  .certs.os.key
' "${bundle}" >/dev/null

printf 'Generating talosconfig...\n'

# The Kubernetes endpoint positional argument is not used when the only
# requested output type is talosconfig, but talosctl still requires it.
talosctl gen config \
    "${cluster_name}" \
    "https://127.0.0.1:6443" \
    --with-secrets "${bundle}" \
    --output-types talosconfig \
    --output "${generated_config}"

printf 'Setting Talos API endpoints...\n'

talosctl \
    --talosconfig "${generated_config}" \
    config endpoint \
    "${endpoints[@]}"

printf 'Setting default target nodes...\n'

talosctl \
    --talosconfig "${generated_config}" \
    config node \
    "${nodes[@]}"

mv -f "${generated_config}" "${output}"
chmod 600 "${output}"

printf 'Created %s\n\n' "${output#"${repo_dir}/"}"

talosctl \
    --talosconfig "${output}" \
    config info