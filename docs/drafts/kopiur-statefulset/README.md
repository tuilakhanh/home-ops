# Kopiur StatefulSet migration

The GitOps manifests now convert all 23 existing Kopiur backup-component consumers to restore-backed StatefulSet claim templates. This implements the pattern introduced in onedr0p/home-ops at [9ccbadf](https://github.com/onedr0p/home-ops/commit/9ccbadf2998793687699045276c93e210c970795) and developed through [8b6210c](https://github.com/onedr0p/home-ops/commit/8b6210cbd824781a4139af0ef90d8ddecff51e0b). The previously supplied hashes were newest first.

Status: all 23 live cutovers are complete. All workloads and Flux resources are Ready, every new claim restored its exact final snapshot, and every backup from a new claim succeeded. Old PVCs and Restores remain retained for rollback. The current-cluster fleet audit passed; [verification.json](./verification.json) records the result. See [LIVE-STATUS.md](./LIVE-STATUS.md) for per-app commits, final snapshot IDs, restore evidence, and backups from the new claims. The implementation and validation notes below describe the conversion. Unrelated working-tree changes are retained.

## Implementation

- `kubernetes/components/kopiur/statefulset` provides SnapshotPolicy, SnapshotSchedule, and Restore. PVCs are created by each StatefulSet's volumeClaimTemplates.
- Snapshot sources match `<template>-<statefulset>-0`. `sourcePathOverride: /pvc/${APP}` retains the old backup identity, together with the unchanged policy name, namespace, and repository.
- Each app keeps its live claim capacity, `miroir-local` storage, primary mount paths, security settings, and other volumes. Data volumes keep the template name `data`; others use `config`.
- Restores run with application `KOPIUR_PUID`/`KOPIUR_PGID` and fsGroup. Existing overrides 65534 (cliproxyapi) and 999 (MySQL) remain. Forgejo uses 1000 and `nas`; Jellyfin also keeps `nas` and its compressor override.
- Every migrated app sets `KOPIUR_ON_MISSING_SNAPSHOT: Fail`; missing backup data must block migration. The reusable component's default remains Continue for deliberate empty bootstraps.
- StatefulSet PVC retention is explicitly Retain for deletion and scale-down.
- `kubernetes/components/kopiur/legacy-pvc` temporarily keeps each old standalone claim in desired state, annotated `kustomize.toolkit.fluxcd.io/prune: disabled`. The old claims remain available for rollback. The new StatefulSets mount only their new claims.
- Existing zeroscaler consumers explicitly target StatefulSet. The shared Deployment default stays unchanged for unrelated workloads.

The old backup component is retained for compatibility; no application references it after the 23 cutovers. Legacy PVC and Restore objects stay in desired state through the legacy-pvc component for the rollback window. Remove that component only after validation; its prune annotations leave the old resources for explicit cleanup.

## App-specific changes

Recyclarr follows upstream's conversion from CronJob to a long-running StatefulSet. Its image's built-in scheduler uses `CRON_SCHEDULE: "0 0 * * *"`; the one-shot `sync` args and CronJob-only fields are removed. Its API keys, config map, temporary data location, and resource settings remain.

Forgejo chart 17.3.2 only emits a Deployment. A targeted Helm post-render patch changes it to a StatefulSet and adds the data claim template; the chart continues to generate its configuration, init containers, services, and routes. `persistence.mount: false` removes the chart's standalone data-volume reference so the StatefulSet template supplies `data`. An extra headless Service supplies the governing service. Preserve this post-render check when upgrading Forgejo's chart.

MySQL (`default/cs-agent-mysql`) previously ran as a StatefulSet with an external PVC. Adding a claim template was an immutable spec change, so the stopped StatefulSet was recreated after both client Deployments were quiesced and its final snapshot was verified. The restored database has the same six tables and an identical schema; the web client can query it. Client replicas were restored to game=0 and web=1. The original PVC and dependencies remain intact. No automatic force/recreation setting is enabled.

Shoko and Jellyfin keep their separate metadata claims; AdGuard Home keeps its work claim; cliproxyapi keeps its configuration claim. Only the primary volume already backed up by Kopiur changes. Their extra data still needs its existing protection or a separate backup plan. Sub2api's Valkey controller is unchanged.

Existing workloads outside the backup component (including slskd, Immich, operator-managed databases, and monitoring storage) are unchanged. This migration covers the 23 existing Kopiur consumers, rather than adding new backup policies to unrelated storage.

## Migration inventory

| Namespace / app | Retained old claim | New StatefulSet claim | Size | Repository |
| --- | --- | --- | --- | --- |
| ai / cliproxyapi | cliproxyapi | data-cliproxyapi-0 | 5Gi | cloudflare |
| ai / sub2api | sub2api | data-sub2api-0 | 5Gi | cloudflare |
| default / atuin | atuin | config-atuin-0 | 1Gi | cloudflare |
| default / cs-agent-mysql | cs-agent-mysql | data-cs-agent-mysql-0 | 5Gi | cloudflare |
| default / thelounge | thelounge | config-thelounge-0 | 1Gi | cloudflare |
| dev / forgejo | forgejo | data-forgejo-0 | 10Gi | nas |
| download / autobrr | autobrr | config-autobrr-0 | 5Gi | cloudflare |
| download / bazarr | bazarr | config-bazarr-0 | 5Gi | cloudflare |
| download / bazarr-anime | bazarr-anime | config-bazarr-anime-0 | 5Gi | cloudflare |
| download / brrpolice | brrpolice | data-brrpolice-0 | 1Gi | cloudflare |
| download / prowlarr | prowlarr | config-prowlarr-0 | 1Gi | cloudflare |
| download / qbittorrent | qbittorrent | config-qbittorrent-0 | 1Gi | cloudflare |
| download / qui | qui | config-qui-0 | 2Gi | cloudflare |
| download / radarr | radarr | config-radarr-0 | 1Gi | cloudflare |
| download / radarr-anime | radarr-anime | config-radarr-anime-0 | 1Gi | cloudflare |
| download / recyclarr | recyclarr | config-recyclarr-0 | 512Mi | cloudflare |
| download / sonarr | sonarr | config-sonarr-0 | 1Gi | cloudflare |
| download / sonarr-anime | sonarr-anime | config-sonarr-anime-0 | 1Gi | cloudflare |
| media / jellyfin | jellyfin | config-jellyfin-0 | 25Gi | nas |
| media / seerr | seerr | config-seerr-0 | 5Gi | cloudflare |
| media / shoko | shoko | config-shoko-0 | 1Gi | cloudflare |
| network / adguard-home | adguard-home | config-adguard-home-0 | 1Gi | cloudflare |
| security / vaultwarden | vaultwarden | data-vaultwarden-0 | 5Gi | cloudflare |

## Cutover: one application at a time

Do not deploy this batch as an unattended fleet-wide cutover. A controller conversion does not copy current writes by itself. The new claims restore snapshots; existing bound PVCs cannot be renamed or repopulated merely by editing dataSourceRef.

1. Record the original workload configuration, replica count, PVC/PV identity, repository, and policy identity. Apply the legacy PVC protection as a separate initial step before switching controllers. Verify the old PVC's prune-disabled annotation. Keep dependent data and external databases accounted for.
2. Suspend the app's Flux Kustomization/HelmRelease and SnapshotSchedule for the controlled cutover. Coordinate dependency ordering; for MySQL stop both cs-agent client Deployments (`cs-agent-cs2` and `cs-agent-web`) too, recording and restoring their individual replica counts. For Forgejo account for the database and stop repository writes. Verify all writers to the primary PVC have stopped.
3. While the policy still references the old claim, take a final snapshot. Wait for a newer lastSuccessfulSnapshot timestamp with Ready=True and no Stalled=True; record the final snapshot ID. Do not use the policy after it has switched to the new PVC to take the old volume's final backup.
4. Review the Restore source against the final snapshot. Existing Restores may contain resolved snapshot IDs from old claims; do not treat top-level Ready=True as proof that a new claim restored the latest data. Validate each new claim's own resolution. This implementation gives each template a fresh `<app>-statefulset` Restore, retains the original Restore, and suspends the schedule while the final snapshot is selected. Compare the new claim's resolved ID with the final snapshot before accepting the cutover. Do not delete existing Restore objects to clear status.
5. Deliver that app's manifests through the normal GitOps process and coordinate resuming reconciliation with its Helm upgrade. Ensure the old writer cannot restart after the final snapshot. For MySQL, explicitly recreate the existing StatefulSet during this window; changing the template cannot be applied in place.
6. Verify the new claim's Restore status entry is Populated/RestoreSucceeded with the intended final snapshot ID, PVC Bound, ownership correct, workload healthy, and actual application data present. WaitForFirstConsumer claims can remain Pending while scheduling/population proceeds; inspect claim events and mover jobs if stalled.
7. Confirm the SnapshotPolicy points to the new PVC while retaining the old resolved backup identity. Resume its schedule and prove a successful snapshot from the new claim before moving to the next app.
8. Keep the legacy-pvc component during the rollback window. Once the migration is accepted, it can be removed; its prune annotations preserve the old claim and Restore. Deletion of a PVC or PV requires explicit approval; `miroir-local` has reclaimPolicy Delete. Rollback requires stopping the new writer first; any writes made after cutover require separate reconciliation.

Read-only cluster commands and future operations must always specify `--kubeconfig ./kubeconfig` (current cluster). The old-cluster kubeconfig1 is not involved in these same-cluster controller changes.

## Verification

Each app was rendered before and after with its actual pinned Helm chart (app-template 5.3.0 or Forgejo 17.3.2). Checks compare all container/init-container specifications, primary mounts, pod security contexts, other volumes, and other controllers. Recyclarr's intentional scheduling change is checked separately. All 23 passed before cutover.

Each app and its Flux components are also built together with Kustomize and app substitutions. Checks match the policy source, legacy claim protection, repository, missing-snapshot behavior, and autoscaler target to the rendered StatefulSet. Strict server-side dry-run validation checks the Kopiur resources, retained claims, autoscalers, and new workloads against the current API. Before cutover, MySQL's existing StatefulSet rejected its immutable template change as expected; a fresh-object dry-run validated its replacement schema separately.

The live audit additionally checked each claiming PVC's exact restored snapshot ID, successful retained final and post-cutover Snapshot objects, Bound old and new claims, live pod mounts, StatefulSet retention, autoscaler targets, repository identity, active backup schedules, and resumed Flux reconciliation. MySQL schema and client access and AdGuard Home configuration and DNS checks passed. See [LIVE-STATUS.md](./LIVE-STATUS.md) and [verification.json](./verification.json) for the evidence.
