# Live migration status

Updated 2026-11-27T17:17:12.317375+00:00. 23/23 apps deployed; 23/23 post-cutover backups verified. Old PVCs and Restores are retained.

Shared components: [877b1a65](https://github.com/tuilakhanh/home-ops/commit/877b1a65e5e752c3fcb3667e85da067b43fb8ae6).

| Namespace / app | Phase | App commit | New PVC |
| --- | --- | --- | --- |
| ai / cliproxyapi | Complete | [46262498](https://github.com/tuilakhanh/home-ops/commit/46262498a36605ccd69abfb3ffea367d7dde4afb) | data-cliproxyapi-0 |
| ai / sub2api | Complete | [476b2fc7](https://github.com/tuilakhanh/home-ops/commit/476b2fc7fb589450561b884adae751fa785f2a1e) | data-sub2api-0 |
| default / atuin | Complete | [8c961b49](https://github.com/tuilakhanh/home-ops/commit/8c961b49a241b8d0efa6a47ada7c002f2a53dabf) | config-atuin-0 |
| default / cs-agent-mysql | Complete | [8dbfe402](https://github.com/tuilakhanh/home-ops/commit/8dbfe40262caa50b2ce4ff8889fcf28ae753fdea) | data-cs-agent-mysql-0 |
| default / thelounge | Complete | [212fed0f](https://github.com/tuilakhanh/home-ops/commit/212fed0f28d0d96fdcd9a24e66272b61444ebc45) | config-thelounge-0 |
| dev / forgejo | Complete | [73abd031](https://github.com/tuilakhanh/home-ops/commit/73abd0316a2a8cea8b4b84a838f6bbe0cd49f176) | data-forgejo-0 |
| download / autobrr | Complete | [6adead54](https://github.com/tuilakhanh/home-ops/commit/6adead5429085839067cd5d6470ffaf4a2bd6527) | config-autobrr-0 |
| download / bazarr | Complete | [ae122aa4](https://github.com/tuilakhanh/home-ops/commit/ae122aa4543d2f0045553e8411bbe8c5c141b838) | config-bazarr-0 |
| download / bazarr-anime | Complete | [ff274c0c](https://github.com/tuilakhanh/home-ops/commit/ff274c0c308e7ed5927d85c719ad560cf6442fdc) | config-bazarr-anime-0 |
| download / brrpolice | Complete | [c86baab8](https://github.com/tuilakhanh/home-ops/commit/c86baab8051b9179a4629d4e1051103442633cf2) | data-brrpolice-0 |
| download / prowlarr | Complete | [6e56d4a9](https://github.com/tuilakhanh/home-ops/commit/6e56d4a9de2787b9c57a8096a2f96cede697ad97) | config-prowlarr-0 |
| download / qbittorrent | Complete | [a22b44aa](https://github.com/tuilakhanh/home-ops/commit/a22b44aad49a25321c69513b64deaa84a7570410) | config-qbittorrent-0 |
| download / qui | Complete | [ebff80a3](https://github.com/tuilakhanh/home-ops/commit/ebff80a3dcadbcbe665c3919fc65b8dc8f12e8bc) | config-qui-0 |
| download / radarr | Complete | [dd0cafd4](https://github.com/tuilakhanh/home-ops/commit/dd0cafd4825ec8905ac493304c72ae65e0a9f01b) | config-radarr-0 |
| download / radarr-anime | Complete | [24d34313](https://github.com/tuilakhanh/home-ops/commit/24d3431325f04770f92c334d552cda90f59ddb33) | config-radarr-anime-0 |
| download / recyclarr | Complete | [7357f31d](https://github.com/tuilakhanh/home-ops/commit/7357f31d16d8cd7a041b6c3caac806f73c914a0d) | config-recyclarr-0 |
| download / sonarr | Complete | [fe23d796](https://github.com/tuilakhanh/home-ops/commit/fe23d7968527ed226216a31288d4aa69be7b6962) | config-sonarr-0 |
| download / sonarr-anime | Complete | [0c5a5238](https://github.com/tuilakhanh/home-ops/commit/0c5a5238acf358a0a4fa7db5053f8c2ccc47c14e) | config-sonarr-anime-0 |
| media / jellyfin | Complete | [9b96d95a](https://github.com/tuilakhanh/home-ops/commit/9b96d95af433064b59593fb56e27fc6b99758e37) | config-jellyfin-0 |
| media / seerr | Complete | [d58b5ba4](https://github.com/tuilakhanh/home-ops/commit/d58b5ba4e8ee1fd89927ba0ea1cb0e5020e493e7) | config-seerr-0 |
| media / shoko | Complete | [19be6df7](https://github.com/tuilakhanh/home-ops/commit/19be6df72c4e8507d5eeca860c9f040131c56d99) | config-shoko-0 |
| network / adguard-home | Complete | [d1fd089e](https://github.com/tuilakhanh/home-ops/commit/d1fd089eb5c9dc486f8d71419969f06cec426c72) | config-adguard-home-0 |
| security / vaultwarden | Complete | [8e7ad6f7](https://github.com/tuilakhanh/home-ops/commit/8e7ad6f7e190b2e3bbaef04062bc5eabfc607593) | data-vaultwarden-0 |

## Snapshot evidence

The claiming PVC must resolve to the exact final snapshot below. The verification snapshot is produced from the new claim after rollout.

| App | Final / restored snapshot | Backup from new claim | Logical bytes before / after |
| --- | --- | --- | --- |
| cliproxyapi | 89d23c90141a999ff5bf99871061aeeb | ebdfce08a649123133eb8009d3e05f4f | 289605 / 289605 |
| sub2api | 9ee42305eeb8c458018f3260f3457728 | 4dc37555e60a0a9a63d28ec083d04468 | 65132313 / 58883247 |
| atuin | b6ed783b8dd7b0e5ae36690d7acc85b6 | 7f48707de1c0010531a0c21a5dac7b55 | 793 / 793 |
| cs-agent-mysql | 0020021d0542866a661da31088d0db29 | ae8ec2d055fef071d762e77f144ac9d0 | 202703755 / 216106040 |
| thelounge | 2188291f5031c60ce20103bc4cc2c23b | 8fc25bfb299cd2e4c8d0d69ed367bdb9 | 20361 / 20361 |
| forgejo | 81f323407ba9363900e5dbaa960fb6c6 | 410659f1e346d6f9bdaa78f1bedc7570 | 1388820237 / 1388820237 |
| autobrr | 59ee07e36884571a2d88a667c0241a06 | 0c233db4e5bc3aaea162e8cb69388f37 | 1432351103 / 1432351103 |
| bazarr | 0f9de9527d3155c8b094db517ff52fc5 | 32d465500ae39af37e52ba728eb3fe00 | 195226001 / 199229071 |
| bazarr-anime | 7c7dfa4883293dec8c8f3608fcb8e8e7 | 086c8055f55819b4300becf62200c34a | 44996580 / 48936095 |
| brrpolice | 2284b623dfd1950d193625fb42229d45 | ee2cd53f11fee7038c6b0fdfc6008e92 | 18767872 / 19319792 |
| prowlarr | fecde0f58ce553f4f6eb59e815c63286 | 4e156acfe607a05c4c869170eab4d762 | 66006205 / 66008066 |
| qbittorrent | 9057a89cfe8cb5a1b6077d629d563c4e | ed3fc74452749d5fa0d2699ebb037446 | 82912503 / 108789639 |
| qui | 2491419cbc14e913e4da2a88200444a4 | c520390f41a208f040cf91574d06b964 | 42303886 / 38233326 |
| radarr | 346e6fa42b0b8b49cf4f0d2b738ed0d1 | 2c6f79ed2517e16be30e9e608492701b | 356467633 / 356469603 |
| radarr-anime | b50196f5b23bf44ae963b2e0bd4471fc | 394037378e025f4ea5235a37c90b7cd2 | 95355685 / 95357376 |
| recyclarr | eaa9a6dd67774bf429b1f1f526892dd2 | d40d4478e8eeddc4171a48b146875885 | 294663720 / 294663720 |
| sonarr | 0238c538f3897358fa53b08e39515eb4 | 7b7613f7f9189e32e11dbbfbb57db9bc | 148935815 / 148937707 |
| sonarr-anime | 4e9429fe3942c94cb1212bf97989fa71 | 9b1e433790d61ff4f97e4e9eba4579df | 366512087 / 366514309 |
| jellyfin | cbb419f4a4a5495ac9a6f87a1cb87f1e | 628b7ecbe97bc741c8824f0c7d46dc93 | 22517134422 / 22517221529 |
| seerr | 4d9e171b7b54c288b309ed7ae354163f | 03f9150b86953ed983bcd19771f39c2d | 989239165 / 989240082 |
| shoko | 180d82c2b8cc2aa6340467385893cfac | abc6e9bc93d8744a1a025435af294863 | 456882423 / 456897039 |
| adguard-home | cdfa4ccb0741a05ffe8ff35e7d619540 | 6d7e5a48a2b63ffe396ed5e96ba458e1 | 5710 / 5710 |
| vaultwarden | 160fe2133d3d284b940685c0bc5fba17 | 087b102f24f044aecfb73dc9000e5b6d | 5709630 / 5709630 |

## Final audit and application checks

All 23 apps passed the current-cluster fleet audit. Each new claim has `Populated` / `RestoreSucceeded` with its exact final snapshot ID, and both retained Snapshot objects report success with no failed files. Helm and Flux are Ready at their current generations, reconciliation and backup schedules are resumed, StatefulSets mount the new primary claims, and autoscalers target StatefulSets. Old PVCs and original Restore objects remain protected from pruning. Detailed results: [verification.json](./verification.json).

- MySQL: the stopped StatefulSet was recreated to add its claim template. The restored schema is byte-for-byte identical and contains the same six application tables. The web client successfully queried the database with its own credentials. Original client replicas are restored: `cs-agent-cs2=0`, `cs-agent-web=1`.
- AdGuard Home: the restored configuration checksum matches the original, the separate work PVC is unchanged, and DNS queries to `192.168.1.102` succeed over UDP and TCP. A workstation DNS failure interrupted its first push while AdGuard was stopped; a command-scoped public-DNS address resolved the retry. Normal workstation DNS works again after rollout.
- Recyclarr: its built-in `supercronic` scheduler retains `0 0 * * *` in `Asia/Ho_Chi_Minh`, as verified during cutover.

No old claims, PVs, or original Restore objects were deleted. Keep the legacy-pvc components for the rollback window; removing or deleting old data is separate follow-up work. Only the current cluster (`kubeconfig`) was used for these same-cluster cutovers.
