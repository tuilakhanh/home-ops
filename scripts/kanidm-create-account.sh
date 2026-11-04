#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Create a Kanidm person account through Kaniop and print its one-time reset URL.

Usage:
  kanidm-create-account.sh <username> <display-name> [email] [--group <group>...]
                           [--create-group <group>...]

Examples:
  kanidm-create-account.sh alice "Alice Nguyen" alice@example.com --group forgejo_users
  kanidm-create-account.sh admin "Admin User" --group forgejo_users --group forgejo_admins

Environment:
  KUBECONFIG        Optional kubeconfig path.
  KANIDM_NAMESPACE  Account CR namespace (default: security).
  KANIDM_REF_NAMESPACE  Kanidm resource namespace (default: security).
  KANIDM_NAME       Kanidm resource name (default: sso).
  KANIDM_GROUP_NAMESPACE  Namespace for newly created groups (default: security).
  TOKEN_TTL         Reset-link lifetime in seconds (default: 86400).
EOF
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" || $# -lt 2 ]]; then
  usage
  [[ $# -ge 2 ]] || exit 0
  [[ ${1:-} == "-h" || ${1:-} == "--help" ]] && exit 0
  exit 2
fi

username=$1
display_name=$2
shift 2
email=""
groups=()
create_groups=()
if [[ ${1:-} != "" && ${1:-} != "--group" ]]; then
  email=$1
  shift
fi
while [[ $# -gt 0 ]]; do
  case $1 in
    --group)
      [[ ${2:-} != "" && ${2:-} != --* ]] || {
        printf 'error: --group requires a group name\n' >&2
        exit 2
      }
      groups+=("$2")
      shift 2
      ;;
    --create-group)
      [[ ${2:-} != "" && ${2:-} != --* ]] || {
        printf 'error: --create-group requires a group name\n' >&2
        exit 2
      }
      groups+=("$2")
      create_groups+=("$2")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'error: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done
namespace=${KANIDM_NAMESPACE:-security}
kanidm_namespace=${KANIDM_REF_NAMESPACE:-security}
kanidm_name=${KANIDM_NAME:-sso}
group_namespace_default=${KANIDM_GROUP_NAMESPACE:-security}
token_ttl=${TOKEN_TTL:-86400}

for command in kubectl jq; do
  command -v "$command" >/dev/null 2>&1 || {
    printf 'error: %s is required\n' "$command" >&2
    exit 1
  }
done

[[ $username =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$ ]] || {
  printf 'error: username must be a Kubernetes-safe lowercase name: %s\n' "$username" >&2
  exit 2
}

[[ $token_ttl =~ ^[0-9]+$ && $token_ttl -ge 300 && $token_ttl -le 86400 ]] || {
  printf 'error: TOKEN_TTL must be between 300 and 86400 seconds\n' >&2
  exit 2
}

manifest=$(jq -n \
  --arg username "$username" \
  --arg display_name "$display_name" \
  --arg email "$email" \
  --arg kanidm_name "$kanidm_name" \
  --arg namespace "$namespace" \
  --arg kanidm_namespace "$kanidm_namespace" \
  --argjson token_ttl "$token_ttl" '
  {
    apiVersion: "kaniop.rs/v1beta1",
    kind: "KanidmPersonAccount",
    metadata: {
      name: $username,
      namespace: $namespace
    },
    spec: {
      kanidmRef: {
        name: $kanidm_name,
        namespace: $kanidm_namespace
      },
      personAttributes: (
        {displayname: $display_name}
        + (if $email == "" then {} else {mail: [$email]} end)
      ),
      credentialsTokenTtl: $token_ttl,
      credentialBootstrapDelivery: "event"
    }
  }')

printf 'Creating or updating %s in namespace %s...\n' "$username" "$namespace"
printf '%s\n' "$manifest" | kubectl -n "$namespace" apply --server-side --field-manager=kanidm-create-account -f -

kubectl -n "$namespace" wait \
  --for=jsonpath='{.status.ready}'=true \
  "kanidmpersonaccount/$username" \
  --timeout=180s >/dev/null

for group in "${groups[@]}"; do
  group_ref=$(kubectl get kanidmgroups --all-namespaces -o json | jq -r \
    --arg group "$group" \
    --arg kanidm_name "$kanidm_name" \
    --arg kanidm_namespace "$kanidm_namespace" '
      [.items[]
       | select(.spec.kanidmRef.name == $kanidm_name)
       | select((.spec.kanidmRef.namespace // .metadata.namespace) == $kanidm_namespace)
       | select(.spec.kanidmName == $group or .metadata.name == $group)
       | [.metadata.namespace, .metadata.name]][0]
      | if . == null then empty else @tsv end')

  if [[ -z $group_ref ]]; then
    should_create=false
    for create_group in "${create_groups[@]}"; do
      [[ $create_group == "$group" ]] && should_create=true
    done

    if [[ $should_create != true ]]; then
      printf 'error: KanidmGroup %s for %s/%s was not found (use --create-group to create it)\n' "$group" "$kanidm_namespace" "$kanidm_name" >&2
      exit 1
    fi

    group_resource=$(printf '%s' "$group" | tr '[:upper:]' '[:lower:]' | tr '_' '-' | tr -cd 'a-z0-9.-')
    group_resource=${group_resource:0:63}
    group_resource=${group_resource%-}
    [[ -n $group_resource ]] || {
      printf 'error: group name %s cannot become a Kubernetes resource name\n' "$group" >&2
      exit 2
    }

    group_manifest=$(jq -n \
      --arg resource_name "$group_resource" \
      --arg group "$group" \
      --arg group_namespace "$group_namespace_default" \
      --arg kanidm_name "$kanidm_name" \
      --arg kanidm_namespace "$kanidm_namespace" \
      --arg username "$username" '
      {
        apiVersion: "kaniop.rs/v1beta1",
        kind: "KanidmGroup",
        metadata: {
          name: $resource_name,
          namespace: $group_namespace
        },
        spec: {
          kanidmName: $group,
          kanidmRef: {
            name: $kanidm_name,
            namespace: $kanidm_namespace
          },
          description: ("Created by kanidm-create-account for " + $group),
          members: [$username]
        }
      }')
    printf '%s\n' "$group_manifest" | kubectl apply --server-side --field-manager=kanidm-create-account -f -
    kubectl -n "$group_namespace_default" wait \
      --for=jsonpath='{.status.ready}'=true \
      "kanidmgroup/$group_resource" \
      --timeout=180s >/dev/null
    group_ref=$(printf '%s\t%s' "$group_namespace_default" "$group_resource")
  fi

  IFS=$'\t' read -r group_namespace group_resource <<<"$group_ref"
  current_group=$(kubectl -n "$group_namespace" get kanidmgroup "$group_resource" -o json)
  members=$(jq -c --arg username "$username" \
    '(.spec.members // []) | if index($username) then . else . + [$username] end' <<<"$current_group")
  patch=$(jq -nc --argjson members "$members" '{spec: {members: $members}}')
  kubectl -n "$group_namespace" patch kanidmgroup "$group_resource" --type=merge -p "$patch" >/dev/null
  printf 'Added %s to %s\n' "$username" "$group"
done

printf 'Account is ready. Waiting for the one-time reset URL...\n'
for _ in {1..30}; do
  note=$(kubectl -n "$namespace" get events \
    --field-selector="involvedObject.kind=KanidmPersonAccount,involvedObject.name=$username,reason=TokenCreated" \
    -o json | jq -r '
      [.items[] | select(.note != null)]
      | sort_by(.eventTime // .lastTimestamp // .metadata.creationTimestamp)
      | last.note // empty')

  if [[ -n $note ]]; then
    printf '\n%s\n' "$note"
    exit 0
  fi
  sleep 2
done

printf 'error: account was created, but no reset URL event was found.\n' >&2
printf 'Run:\n  kubectl -n %s describe kanidmpersonaccount %s\n' "$namespace" "$username" >&2
exit 1
