# Cilium egress policies

Adapted from https://github.com/bjw-s-labs/home-ops/tree/main/kubernetes/apps/kube-system/cilium/netpols.

These cluster-wide policies restrict egress by **pod label**, not namespace or
HelmRelease label. Unlabelled pods retain unrestricted connectivity. These shared policies do not restrict ingress. Application-specific ingress
policies live beside each external application. CyberChef and IT Tools opt into DNS-only egress because their
application logic runs in the browser.

Set labels under `values.controllers.<controller>.pod.labels`:

- `egress.policy.home.arpa/block-all: "true"`: enable default-deny egress;
  the shared DNS allowance still applies. This is not an explicit deny rule.
- `egress.policy.home.arpa/internet: "true"`: allow Cilium's `world` entity.
- `egress.policy.home.arpa/kube-api: "true"`: allow the Kubernetes API entity.

The presence of any of these label keys removes the default unrestricted
allowance, even when its value is `"false"`; remove a key to opt out. Multiple
labels and any application-specific CiliumNetworkPolicy allow rules are
additive. `block-all` does not override another allow policy.

All pods may query CoreDNS in kube-system over UDP/TCP 53. The DNS L7 rule
allows all query names and enables Cilium DNS observation for future FQDN
rules; it requires Cilium's L7 proxy support (enabled in this cluster).

`world` includes non-cluster private/LAN IPs, not just public internet IPs.
This policy is not a LAN isolation boundary. Add explicit CIDR/port rules for
workloads requiring more precise access, and review other matching allow
policies before relying on isolation. Host-network workloads are not isolated
by these pod endpoint policies.

For other applications, inventory database, cache, API, LAN, and external
connections before adding opt-in labels. Keep application-specific allowances
beside the application's manifests. Do not add blanket restrictions to
controllers or storage components without those allowances.

The separate `cilium-netpols` Flux Kustomization depends on `cilium` so the
policy CRDs are available. Removing a restrictive pod label restores the
baseline allowance after reconciliation; deleting that Kustomization prunes
the shared policies.

Validate locally without deploying:

```sh
kustomize build kubernetes/apps/kube-system/cilium/netpols > /tmp/cilium-netpols.yaml
kubectl apply --dry-run=server -f /tmp/cilium-netpols.yaml
```

## External application ingress

External app HelmReleases define `values.networkpolicies` with `type: cilium`
and an explicit controller using app-template 5.3.0. Policies select the exact controller labels rendered by
app-template and allow only the external Envoy pods in `network` on the
backend container port. Immich ML and Valkey are not selected by the Immich
server policy. Filebrowser is covered for when its disabled Kustomization is
enabled again.

Additional allowances retain Seerr-to-Jellyfin access, CS agent web-to-game
TCP access, and Flux notification API/Prometheus traffic. The game policy
allows Envoy TCP and UDP on 27015. Direct LAN clients and other unlisted pod
callers will be blocked; use the external Gateway or add an explicit allowance
for a required integration. Kubelet health probes retain Cilium's default
local-host access. No blanket ingress policy is applied to Envoy itself.

The Flux webhook policy remains a standalone CiliumNetworkPolicy because
FluxInstance is managed by flux-operator rather than app-template.
