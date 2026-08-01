set lazy
set default-list
set default-script
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

talos_dir := source_directory()
secrets_file := talos_dir + "/secrets.sops.yaml"

[private]
[script]
default:
    just -l talos

[confirm('Generate a new Talos client configuration [y|N] ?')]
[doc('Generate TALOSCONFIG from encrypted Talos secrets')]
gen-talosconfig cluster_name *args:
    : "${TALOSCONFIG:?TALOSCONFIG environment variable is not set}"
    mkdir -p "$(dirname "$TALOSCONFIG")"
    bash "{{ talos_dir }}/scripts/gen-talosconfig.sh" --cluster-name "{{ cluster_name }}" {{ args }}
    if [[ ! -s "$TALOSCONFIG" ]]; then
        printf 'talosconfig was not created: %s\n' "$TALOSCONFIG" >&2
        exit 1
    fi
    chmod 600 "$TALOSCONFIG"
    talosctl --talosconfig "$TALOSCONFIG" config info

[doc('Show the active Talos client configuration')]
config-info:
    : "${TALOSCONFIG:?TALOSCONFIG environment variable is not set}"
    if [[ ! -s "$TALOSCONFIG" ]]; then
        printf 'talosconfig not found: %s\n' "$TALOSCONFIG" >&2
        exit 1
    fi
    talosctl --talosconfig "$TALOSCONFIG" config info

[doc('Set Talos API endpoints in TALOSCONFIG')]
config-endpoint +endpoints:
    : "${TALOSCONFIG:?TALOSCONFIG environment variable is not set}"
    if [[ ! -s "$TALOSCONFIG" ]]; then
        printf 'talosconfig not found: %s\n' "$TALOSCONFIG" >&2
        exit 1
    fi
    talosctl --talosconfig "$TALOSCONFIG" config endpoint {{ endpoints }}

[doc('Set default Talos target nodes in TALOSCONFIG')]
config-node +nodes:
    : "${TALOSCONFIG:?TALOSCONFIG environment variable is not set}"
    if [[ ! -s "$TALOSCONFIG" ]]; then
        printf 'talosconfig not found: %s\n' "$TALOSCONFIG" >&2
        exit 1
    fi
    talosctl --talosconfig "$TALOSCONFIG" config node {{ nodes }}

[doc('Download Kubernetes admin credentials to KUBECONFIG')]
kubeconfig controller="" context="main":
    : "${TALOSCONFIG:?TALOSCONFIG environment variable is not set}"
    : "${KUBECONFIG:?KUBECONFIG environment variable is not set}"

    if [[ ! -s "$TALOSCONFIG" ]]; then
        printf 'talosconfig not found: %s\n' "$TALOSCONFIG" >&2
        exit 1
    fi

    target="{{ controller }}"
    if [[ -z "$target" ]]; then
        target="$(talosctl --talosconfig "$TALOSCONFIG" config info --output yaml | yq eval -e -r '.endpoints[0]' -)"
    fi

    if [[ -z "$target" || "$target" == "null" ]]; then
        printf 'No Talos API endpoint is configured.\n' >&2
        exit 1
    fi

    mkdir -p "$(dirname "$KUBECONFIG")"
    printf 'Fetching kubeconfig from %s\n' "$target"
    printf 'Writing kubeconfig to %s\n' "$KUBECONFIG"
    talosctl --talosconfig "$TALOSCONFIG" --nodes "$target" kubeconfig "$KUBECONFIG" --merge=false --force --force-context-name "{{ context }}"
    chmod 600 "$KUBECONFIG"
    printf 'Created %s\n' "$KUBECONFIG"

[confirm('Generate new Talos cluster secrets [y|N] ?')]
[doc('Generate Talos secrets and encrypt them with SOPS')]
init-secrets:
    bash "{{ talos_dir }}/scripts/init-secrets.sh"

[doc('Render Talos configuration for a node')]
render-config node:
    umask 077

    if [[ ! -s "{{ secrets_file }}" ]]; then
        printf 'Encrypted secrets file not found: %s\n' "{{ secrets_file }}" >&2
        exit 1
    fi

    controlplane_node="{{ talos_dir }}/nodes/controlplane/{{ node }}.yaml.j2"
    worker_node="{{ talos_dir }}/nodes/workers/{{ node }}.yaml.j2"

    if [[ -f "$controlplane_node" && -f "$worker_node" ]]; then
        printf 'Node exists in both roles: %s\n' "{{ node }}" >&2
        exit 1
    elif [[ -f "$controlplane_node" ]]; then
        role="controlplane"
        node_template="$controlplane_node"
    elif [[ -f "$worker_node" ]]; then
        role="workers"
        node_template="$worker_node"
    else
        printf 'Node configuration not found for: %s\n' "{{ node }}" >&2
        printf 'Checked:\n' >&2
        printf '  %s\n' "$controlplane_node" >&2
        printf '  %s\n' "$worker_node" >&2
        exit 1
    fi

    role_template="{{ talos_dir }}/${role}.yaml.j2"
    if [[ ! -f "$role_template" ]]; then
        printf 'Role template not found: %s\n' "$role_template" >&2
        exit 1
    fi

    workdir="$(mktemp -d)"
    cleanup() { rm -rf "$workdir"; }
    trap cleanup EXIT INT TERM

    secrets="$workdir/secrets.yaml"
    cluster_config="$workdir/cluster.yaml"
    role_config="$workdir/role.yaml"
    node_config="$workdir/node.yaml"

    sops decrypt "{{ secrets_file }}" > "$secrets"

    talos_version="$(just talos talos-version)"
    kubernetes_version="$(just talos k8s-version)"
    schematic="$(just talos schematic-id "{{ node }}")"

    just template-with-data "{{ talos_dir }}/cluster.yaml.j2" "$secrets" -D "schematic=${schematic}" -D "talos_version=${talos_version}" > "$cluster_config"
    just template-with-data "$role_template" "$secrets" -D "kubernetes_version=${kubernetes_version}" > "$role_config"
    just template-with-data "$node_template" "$secrets" > "$node_config"

    talosctl machineconfig patch "$cluster_config" --patch "@${role_config}" --patch "@${node_config}"

[confirm('Apply Talos config to ' + node + ' [y|N] ?')]
[doc('Apply Talos config to a node')]
apply-node node *args:
    just talos render-config {{ node }} | talosctl -n {{ node }} apply-config -f /dev/stdin {{ args }}

[confirm('Reboot node ' + node + ' [y|N] ?')]
[doc('Power-cycle a Talos node')]
reboot-node node:
    : "${TALOSCONFIG:?TALOSCONFIG environment variable is not set}"
    talosctl --talosconfig "$TALOSCONFIG" --nodes "{{ node }}" reboot --mode powercycle

[confirm('Shutdown node ' + node + ' [y|N] ?')]
[doc('Shutdown a Talos node')]
shutdown-node node *args:
    : "${TALOSCONFIG:?TALOSCONFIG environment variable is not set}"
    talosctl --talosconfig "$TALOSCONFIG" --nodes "{{ node }}" shutdown {{ args }}

[doc('Download Talos machine image')]
download-image version node="":
    schematic="$(just talos schematic-id "{{ node }}")"
    output="{{ talos_dir }}/talos-{{ version }}-${schematic:0:8}.iso"
    curl --fail --location --remove-on-error --retry 5 --retry-delay 5 --retry-all-errors --progress-bar --output "$output" "https://factory.talos.dev/image/${schematic}/{{ version }}/metal-amd64.iso"
    just log info "Downloaded Talos" version "{{ version }}" schematic "$schematic" output "$output"

[private]
schematic-id node="":
    curl --fail --silent --show-error --retry 5 --retry-delay 2 --retry-all-errors --request POST --data-binary "@{{ talos_dir }}/schematic.yaml" "https://factory.talos.dev/schematics" | jq --exit-status --raw-output '.id'

[private]
machine-image node:
    just talos render-config "{{ node }}" | yq eval -e -r 'select(.kind == "UnattendedInstallConfig") | .installer.image' -

[private]
[doc('Fetch Talos version from configuration')]
talos-version:
    yq eval -e -r '.talos_version' "{{ talos_dir }}/version.yaml"

[private]
[doc('Fetch Kubernetes version from configuration')]
k8s-version:
    yq eval -e -r '.k8s_version' "{{ talos_dir }}/version.yaml"
