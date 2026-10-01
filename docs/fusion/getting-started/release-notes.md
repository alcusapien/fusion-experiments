---
title: Release Notes
url: https://dev-doc.photonengine.com/fusion-godot/v3-client-server/getting-started/release-notes
product: fusion-godot
version: v3-client-server
language: en-us
description: "Fusion for Godot release notes and migration guide: singleton rename, connection API changes, replicator types, and interpolation modes. Upgrade in five steps."
timestamp: 2026-07-21
---

# Release Notes

## Migrating to the Latest Fusion SDK

If you are upgrading an existing project from an earlier 3.x preview, walk through the five steps below.

### 1. `FusionClient` Singleton Renamed to `Fusion`

Project-wide find/replace `FusionClient.` → `Fusion.` covers almost everything.
The C++ class name is still `FusionClient`; only the GDScript singleton was renamed.

### 2. Remove `initialize_from_settings()`

Fusion now self-initializes from project settings.
Delete any `initialize_from_settings()` calls and the surrounding `is_initialized()` guard.
Use `Fusion.set_app_id(...)` only if you need to override the App ID at runtime (per-build flavor, remote config); otherwise put it in Project Settings and call `connect_to_photon()` directly.

### 3. Connection Symbols: `server` → `photon`

| Before | After |
| --- | --- |
| `connect_to_server()` | `connect_to_photon()` |
| `is_connected_to_server()` | `is_connected_to_photon()` |
| `disconnect_from_server()` | `disconnect_from_photon()` |
| `connected_to_server` (signal) | `connected_to_photon` |
| `STATUS_CONNECTING` | `STATUS_CONNECTING_TO_PHOTON` |
| `STATUS_CONNECTED` | `STATUS_CONNECTED_TO_PHOTON` |


Other `STATUS_*` values (`STATUS_DISCONNECTED`, `STATUS_JOINING_ROOM`, `STATUS_IN_ROOM`, `STATUS_ERROR`) are unchanged.
The rename disambiguates "connecting to the Photon Cloud" from the Client-Server topology's simulation-server role.

### 4. `FusionReplicator` → `FusionSharedReplicator`

`FusionReplicator` is now an abstract base.
For each replicator node in your scenes: right-click in the Scene tree → **Change Type…** → `FusionSharedReplicator`, then save.
Use `FusionServerReplicator` instead if your room uses Client-Server topology with input prediction.

Update script types to match:

```gdscript
@onready var replicator: FusionSharedReplicator = $FusionReplicator
```

### 5. Re-check `root_interpolation_mode`

The `InterpolationMode` enum was simplified from four modes to two, so saved integers in `.tscn` files now resolve to different modes.

<table class="table">
<thead>
    <tr>
        <th class="empty">&nbsp;</th>
        <th>Old enum</th>
        <th>New enum</th>
    </tr>
</thead>
<tbody>
    <tr>
        <th>0</th>
        <td><code>INTERPOLATION_SPRING_DAMPER</code> (default)</td>
        <td><code>INTERPOLATION_SNAPSHOT</code></td>
    </tr>
    <tr>
        <th>1</th>
        <td><code>INTERPOLATION_SNAPSHOT</code></td>
        <td><code>INTERPOLATION_EXPONENTIAL</code> (default)</td>
    </tr>
    <tr>
        <th>2</th>
        <td><code>INTERPOLATION_SIMPLE_LERP</code></td>
        <td><em>(removed)</em></td>
    </tr>
    <tr>
        <th>3</th>
        <td><code>INTERPOLATION_EXPONENTIAL</code></td>
        <td><em>(removed)</em></td>
    </tr>
</tbody>
</table>


Open each replicator and confirm **Root Interpolation Mode** in the Inspector matches your intent; reset if not.
The exponential mode was previously called `ASYMPTOTIC` and its tuning property prefix changed from `root_asym_*` to `root_smooth_*`.

Exponential Decay is the new default for non-physics smoothing (replacing the removed Spring Damper).
Two error-detection thresholds gate its behaviour: `root_max_smooth_dist` (above this position error, a catch-up term blends in) and `root_no_smooth_dist` (above this error, the value snaps).
Both are world-space distances, so suitable values differ by an order of magnitude between 2D scenes (pixels) and 3D scenes (meters); the defaults (2.0 and 5.0) target 3D and likely need to be raised for 2D projects.

## 3.0.0

### Preview

#### Build 555 (Jul 17, 2026)

**What's New**

- Tooltips documentation for Fusion's Project Settings
- C# bindings
- RoomOptions class for join/create room methods
- Exposed realtime lobby name in RoomOptions
- Fusion Replication tab now shows warnings for invalid properties (ex. missing nodes, non-replicable types)

**Changes**

- FusionRoom.players now returns a typed array of FusionPlayer classes
- FusionClient.room_list and FusionClient.room_list_updated now use typed arrays

**Removed**

- "custom_properties" from FusionRoom.players

**Bug Fixes**

- Fixed: Removed old references to "FusionClient" in XML docs from rename
- Fixed: Issue when reconnecting to photon cloud

#### Build 517 (Jul 01, 2026)

**What's New**

- New signal for on_master_client_changed

**Changes**

- Authority_changed also emitted for master-owned objects when master changed
- Array replication now synchronizes the array's size, Fusion no longer automatically grows the array to the maximum size when spawned. Call `array.resize()` in `_ready()` on the authority if your code assumes the array will always be the maximum size

**Bug Fixes**

- Fixed: Aoi enter is called when becoming master

#### Build 482 (Jun 24, 2026)

**Bug Fixes**

- Fixed: Android libraries are now coming with 16 KB page alignment

#### Build 463 (Jun 11, 2026)

**What's New**

- Comprehensive RPC logs for INFO and above
- Replication to gdscript-defined custom classes
- Regular array replication (primitive and custom classes), besides the existing packed arrays
- Exponential decay (interpolation function) in the Fusion singleton
- Per-property interpolation (exponential for numeric types, snap at half-time for non numerics)
- Option to auto-destroy replicated scenes that go out of IM (AoI and custom), with respawn on re-enter
- Notarization and signing to .dylib (solves quarantine issue on Macs)

**Changes**

- Updated Fusion Core to 3.0.0-r3
- Removed snapshot interpolation (exponential decay replaces all old variations)

**Bug Fixes**

- Fixed: Compilation error with clang on mac
- Fixed: Sub-objs also respawn with destroy-on-exit
- Fixed: Crash when closing the game window while Fusion is running

#### Build 424 (May 07, 2026)

**What's New**

- Warning for non replicable type
- Property path validator with warning icon for replicator

**Bug Fixes**

- Fixed: Issue with wrong data in stats and monitors
- Fixed: Added missing web paths to fusion.gdextension
- Fixed: Added missing web export templates
- Fixed: Issues with authority switch API
- Fixed: Ungarded spawn time log is now INFO
- Fixed: Issue where replicated property settings could be lost when rearranging scene trees

#### Build 407 (May 05, 2026)

**Breaking Changes**

- The singleton previously exposed as `FusionClient` is now `Fusion`. The connect-related methods, signal, and status enums were renamed to disambiguate "connecting to the Photon Cloud" from the Client-Server topology's simulation-server role (where a local peer can itself be the "server")

**What's New**

- Asymptotic decay interpolation mode
- Hability to overhaul shared/auth mode
- Player_joined signal (safe with handshake)
- Pre_spawn_function callable to Spawn()
- Support for RPCs in sub-nodes
- Added inspector tooltips for `spawn_as_sub_object`, `spawn_map_mode`, and `bound_map_index` on `FusionSpawner`
- Added `Fusion.player_left(player_id: int, is_inactive: bool)` signal - fires on every peer when a remote player leaves the room. `is_inactive` distinguishes a TTL-grace disconnect from a permanent leave. In Client-Server topology, the master client uses this to despawn the departed player's character (see the "Despawning on Player Leave" section in [Spawning](../manual/spawning.md))
- Note: `player_joined` is intentionally not exposed in this release — Photon's underlying event fires before Fusion finishes starting locally. A reliable join notification will arrive later via an internal broadcast RPC

**Changes**

- Updated fusion core to protocol v8
- Support to authority switch transaction
- Cleaned up logging for disambiguation
- Refactored input api
- Naming consistency: signal on_process_input(), and process_input(delta) as main entry point
- Changed (potentially breaking): `FusionSpawner` no longer auto-binds as a sub-spawner when placed under a `FusionSharedReplicator`. Sub-spawner mode is now opt-in via the inspector `Spawn As Sub Object` toggle or via `bind_root_replicator()`. Existing scenes using the explicit API are unaffected
- Changed (potentially breaking): `FusionSpawner.spawn_map_mode` default is now `Bound` (was `Unbound`). Spawners inside a registered scene now spawn into that scene's map by default. Set to `Unbound` to opt back into the global-map behavior
- **Migration**
- | Before | After |
- | --- | --- |
- | `FusionClient.xxx` | `Fusion.xxx` |
- | `FusionClient.initialize(app_id, version)` | `Fusion.set_app_id(app_id)` — drop the version. Set `fusion/connection/app_version` in Project Settings, or pass it via `connect_to_photon(..., app_version)` |
- | `FusionClient.initialize_from_settings()` | Delete the call — `connect_to_photon()` initializes from settings automatically |
- | `FusionClient.connect_to_server(...)` | `Fusion.connect_to_photon(...)` — same signature |
- | `FusionClient.disconnect_from_server()` | `Fusion.disconnect_from_photon()` |
- | `FusionClient.is_connected_to_server()` | `Fusion.is_connected_to_photon()` |
- | `FusionClient.connected_to_server` (signal) | `Fusion.connected_to_photon` |
- | `STATUS_CONNECTING` | `STATUS_CONNECTING_TO_PHOTON` |
- | `STATUS_CONNECTED` | `STATUS_CONNECTED_TO_PHOTON` |
- Other status values (`STATUS_DISCONNECTED`, `STATUS_JOINING_ROOM`, `STATUS_IN_ROOM`, `STATUS_ERROR`), signals, room APIs, RPC APIs, scene APIs, interest/AOI APIs and all other members are unchanged — only the connect-related surface was touched
- The `initialize(app_id, app_version)` and `initialize_from_settings()` methods are no longer part of the public API. Use `set_app_id()` for runtime App ID overrides (e.g., per-build flavor, remote config); otherwise put your App ID in Project Settings and call `connect_to_photon()` directly

**Bug Fixes**

- Fixed: Spawn guarded on client-server mode clients
- Fixed: Call-local ignored on target not matching
- Fixed: Call-local now has rpcinfo and sender
- Fixed: Usion monitors under wrong category

#### 20/03/2026

- Fixed crash on disconnect when replicated string properties are active (use-after-free in string handle cleanup)
- Fixed crash when nodes are modified on despawn
- Fixed disconnect on app close not being detected
- Fixed `join_room` and `join_or_create_room` with empty name failing instead of using random matchmaking
- Changed improved snapshot interpolation with asymmetric delay adaptation (faster recovery, slower spike reaction)
- Changed exposed snapshot interpolation tuning parameters in inspector (`max_snapshot_gap`, `adapt_speed_up`, `adapt_speed_down`, `max_delay`)
- Changed decoupled position and rotation teleport detection (each evaluated independently)
- Changed RPC ID hash now includes script class path for uniqueness across scripts
- Added teleport snap mode setting (Source vs Projected) for forecast handler
- Fixed forecast teleports being applied for both rot/pos if only one triggered
- Fixed large-scene hash clash on nodes with same name
- Fixed broadcast RPCs not working due to a wrong early check for replicators (not needed)
- Fixed rotation teleport threshold 0 and 360 now both disable rotation teleport detection
- Fixed position teleport threshold 0 now disables position teleport detection

#### 18/02/2026

- Added `despawn_on_disconnect` option to `FusionSpawner` - controls whether spawned objects are automatically cleaned up when the owning client leaves (enabled by default)
- Added `scene_unloaded` signal to `Fusion` - emitted during disconnect cleanup before the auto-loaded scene is freed
- Fixed disconnect callbacks not being processed correctly

#### 17/02/2026

- Added auto-sync of `velocity` property for CharacterBody2D/3D roots (no manual `.tres` config needed)
- Fixed Replication Editor panel selector not updating when switching between nodes in the scene tree

#### 12/02/2026

- Fixed editor plugin crash on startup by migrating from deprecated `add_control_to_bottom_panel()` to new Godot 4.6 `EditorDock` + `add_dock()` API
- Changed `FusionReplicationEditor` base class from `VBoxContainer` to `EditorDock` with `DOCK_SLOT_BOTTOM` default slot
- Fixed infinite `NOTIFICATION_THEME_CHANGED` loop caused by `add_theme_stylebox_override()` on `EditorDock`
- Removed timer-based deferred setup workaround in `FusionEditorPlugin` (no longer needed)

#### 09/02/2026

- Added sub-objects (dynamic sub-object add)
- Added support for scene/map-objects (and setting for auto loader)
- Added update interval setting
- Fixed array tree editor support (capacity)
- Removed rate from Settings
- Updated Fusion to 3.0.0.728

#### 06/02/2026

- Removed duplicated shadow-copy test from GDExtension plugin
- Fixed other minor concerns from code review

#### 05/02/2026

- Added string serialization support (using string heap)
- Added support for arrays

#### 04/02/2026

- Added different ownership modes to the settings
- Added physics and forecast replication (+ demo and docs)
- Refactored replication mode architecture: transform/physics data auto-synced without .tres config
- Added SmoothingMode enum (None, Interpolate, Forecast)
- Added sleeping state replication for physics objects
- Simplified demo scripts (removed manual interpolation code)

#### 03/02/2026

- Updated to latest Fusion core (3.0.0.625)
- Added main settings asset for Fusion config
- Improved remote object updates using Client->HasBeenUpdatedByPlugin
