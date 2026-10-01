---
title: Syncing Properties
url: https://dev-doc.photonengine.com/fusion-godot/v3-client-server/manual/replication/syncing-properties
product: fusion-godot
version: v3-client-server
language: en-us
description: "Learn how state replication works in Godot with Fusion: networked properties, authority, and keeping every player's game world in sync automatically."
timestamp: 2026-07-21
---

# Syncing Properties

In a multiplayer game, each client runs its own copy of the simulation. Replication is the mechanism that keeps these copies consistent: the authority (a client in Shared-Authority, or the simulation server in Client-Server) writes the definitive values for an object's properties, and the Photon Cloud distributes them to every other client. Without replication, each player would see a different game.

Fusion replicates at the property level. Individual values like position, health or score are tracked independently. The server only sends properties that have changed since the last update, minimizing bandwidth.

## The Replicator Node

`FusionServerReplicator` handles property sync for networked objects, plus input queuing and prediction for the Client-Server input loop. Add it as a child of your networked scene's root node. The simulation server writes authoritative values; clients predict locally and receive corrections. All property sync features described on this page apply.


## Root Replication Modes

The replication mode controls which properties the replicator syncs automatically based on the root node type.

- **REPLICATION_NONE** - no auto-sync; add custom properties via the replicator's bottom panel
- **REPLICATION_AUTO** - auto-detects root node type and syncs accordingly:
- RigidBody2D/3D → position, rotation, linear_velocity, angular_velocity (forecast smoothing)
- CharacterBody2D/3D → position, rotation, velocity (interpolation smoothing)
- Other nodes → position, rotation (interpolation smoothing)

## Smoothing

`root_interpolation_mode` controls how remote values are applied to the root node.
The editor exposes the type-appropriate pair: physics roots (RigidBody2D/3D) see `None` / `Forecast`, all other roots see `None` / `Exponential`.
`Exponential` blends each received value toward the local node using exponential decay; `Forecast` predicts ahead from the latest velocity and corrects against incoming targets; `None` writes every received value directly.
`object_interpolation_time` (default `0.150` s) is the shared decay constant used by the `Exponential` root mode and by per-property interpolation (see [Per-Property Interpolation](#per-property-interpolation) below).

> **Info**
> 
> Exponential interpolation's "Snap Distance" (`root_snap_distance`) and Forecast interpolation's "Teleport Threshold" `root_teleport_threshold` properties are measured in units for 3D nodes and pixels for 2D nodes.
> When using 2D nodes, larger values might be required to avoid snapping / teleporting on every tick.

## Custom Properties

Custom properties are added directly via the replicator's bottom panel in the editor. Use this for game data (health, score, name) beyond what the replication mode auto-syncs. Transform and physics properties should **not** be added. They are handled by `REPLICATION_AUTO`.

Supported types: bool, int, float, String, Vector2, Vector3, Vector4, Quaternion, Color, Node references, Array[T], PackedByteArray, PackedFloat32Array, PackedInt32Array, PackedVector2Array.

**Not yet supported:**

- `Dictionary`; use individual properties or a `Packed*Array` instead

> **Info**
> 
> Custom properties snap to each received value by default.
> Opt-in per-property interpolation is available via the `Interpolate` column on each replication-config entry; see [Per-Property Interpolation](#per-property-interpolation) below.

![Custom properties panel](https://dev-doc.photonengine.com/docs/img/fusion-godot/v3/replicator-custom-properties.png)

*Custom properties panel*

### Property Path Syntax

Property paths use a `node:property` syntax relative to the replicator's root node.

- `:property` - property on the root node
- `child:property` - property on a child node
- `child/grandchild:property` - nested child

```gdscript
":health"             # Root node
"Sprite2D:modulate"   # Child Sprite2D
```

### Strings and Arrays

**Strings** use 2 words (StringHeap handle + generation). Handles are freed automatically when the value changes.

**Arrays** (PackedFloat32Array, PackedInt32Array, PackedVector2Array, etc.) require a fixed `max_capacity` set before spawning.

> **Warning**
> 
> If an array grows beyond its `max_capacity` at runtime, the excess elements are silently dropped during replication. Remote clients will receive a truncated array with no error. Always size `max_capacity` for the worst case your game needs.

### Typed Arrays

`Array[T]` and `Array[ScriptClass]` are the typed companions to packed arrays. Like packed arrays, typed arrays require a fixed maximum capacity set in the replicator. Untyped arrays (`Array`) are not supported.

#### Array of primitives

`Array[Vector3]`, `Array[Color]`, `Array[float]`, and any other primitive supported by `PackedXxxArray` work the same way as a typed array.

#### Array of script classes

`Array[MyClass]` where `MyClass` is a `class_name`-declared script extending `RefCounted` (or `Resource`) with primitive fields. Each element's primitive fields replicate sequentially. The field list is captured once at spawn and reused; add a field to the class and re-spawn (not just reload) to pick it up.

| Field on `MyClass` | Replicates? |
| --- | --- |
| `var health: float` | Yes |
| `var armor: float` | Yes |
| `var max_velocity: Vector2` | Yes |
| `var name: String` | No — strings are silently skipped inside element classes |
| `var target: Node` | No — only primitive fields traverse |


**Rules:**

- Element class must be declared with `class_name`.
- Only primitive fields replicate. `String` and non-primitive fields (Object, Array, Dictionary) are silently skipped.

> **Warning**
> 
> Typed arrays do **not** support per-property interpolation. The Interpolate column on a typed-array row is ignored. The receiver writes incoming values straight into the existing element instances each tick - no `prev_value` dedup, no shadow targets, no lerp. If you need element-level smoothing, interpolate it yourself with `Fusion.interpolate_exponential` against a local shadow copy.

If you need an array of primitives that *does* interpolate (or apply per-property interpolation in any way), put the primitive on the parent node as a standalone property, or split a single composite into individual sub-fields via the picker's "Add All" — those rows each get their own Interpolate column and work as normal.

### Custom Class Instances

A property typed as a `class_name`-declared GDScript class (extending `RefCounted` or `Resource`) with primitive fields can be replicated either by adding every supported field at once or by picking individual fields. Inner classes (a class defined within the same file) are **not** supported.

In the picker, the property appears as a composite row showing the class name with an **Add All** button, plus one child row per supported sub-field. Click **Add All** to add every supported primitive field, or click individual sub-rows to add just those.

Each picked sub-field becomes its own row in the replication config, with its own `Interpolate` column. Field-traversal rules match [Array of script classes](#array-of-script-classes): only primitive fields replicate; `String`, `Object`, nested `Array`, and `Dictionary` fields are silently skipped; the class must be declared with `class_name`.

> **Warning**
> 
> The class instance must be initialized **at declaration time** (e.g. `@export var player: PlayerData = PlayerData.new()`), not in `_ready()`. Proxy data is written by the replicator on received spawn, which happens before `_ready()` runs: a `null` reference at that point will be dereferenced and crash. Unlike typed-array elements, single instances are not auto-created.

Here is a complete example of the feature in use. First, define a `class_name` script extending `RefCounted` (or `Resource`) with primitive fields:

```gdscript
# PlayerData.gd: reusable as a single-instance property or as array elements.
class_name PlayerData extends RefCounted

var health: float = 100.0
var armor: float = 0.0
var max_velocity: Vector2 = Vector2.ZERO
```

Then, on a networked node, you can replicate its primitive fields by declaring a single property of that class. In the replicator's bottom panel, open the picker and choose **Add All** under the `player` composite row to replicate every supported field, or click individual sub-rows to replicate only some. You can also type the path directly (e.g. `:player:health`):

```gdscript
# Single PlayerData on a networked node.
# Must be instantiated at declaration: proxy data arrives before _ready() runs.
@export var player: PlayerData = PlayerData.new()

func _ready() -> void:
    player.health = 100.0
```

Or, you can replicate a fixed-length array of instances of that same class. Array properties are added as a single row (via the picker or by typing the path, e.g. `:squad`); element field selection is not exposed, so every supported primitive field on the element class is always replicated:

```gdscript
# Array[PlayerData] reuses the same class.
# Slots are pre-filled with PlayerData.new() before _ready runs, so indexing is safe from the first frame.
# See "Array of script classes" above for the full rules.
@export var squad: Array[PlayerData]

func _ready() -> void:
    squad[0].health = 80.0
```

### Node References

Properties of type `Node` (or `Object`) can reference other **networked root** nodes. On the wire, each reference is stored as a Fusion ObjectId (2 words: Origin + Counter).

The referenced node must be a **networked root**, the parent node of a replicator. This includes spawned object roots, sub-object roots and scene object roots. Child nodes within a networked object cannot be referenced. Non-networked nodes and `null` both serialize as `(0, 0)` and resolve to `null` on the remote end.

```gdscript
# Authority sets a reference to another networked node
partner = get_node("/root/Main/Player2")

# Remote must null-check - reference resolves to null if target is outside AoI or destroyed
if partner:
    print(partner.name)  # "Player2"
```

**Resolution rules:**

- If the referenced node is in the remote client's Area of Interest, it resolves to the local Node.
- If the referenced node is outside AoI, destroyed, or not yet spawned, it resolves to `null`.
- Setting the property to `null` or a non-networked node on authority sends `null` to all remotes.
- Scene objects loaded via `Fusion.load_scene()` work the same way. The reference resolves once the remote client has loaded the scene.

### Per-Property Interpolation

Each entry in `FusionReplicationConfig` has an `Interpolate` column with three values.
When set to `Interpolate` or `Interpolate Angle`, the received value is held as a shadow target on remote clients and applied per frame instead of being written immediately.

<table class="table">
<thead>
<tr>
<th>Value</th>
<th>Behavior</th>
</tr>
</thead>
<tbody>
<tr>
<th>None</th>
<td>Default. Each received value is written directly to the node.</td>
</tr>
<tr>
<th>Interpolate</th>
<td>For numeric types (FLOAT, VECTOR2, VECTOR3, QUATERNION) the local value blends toward the target each frame using exponential decay over <code>object_interpolation_time</code>. Other supported types (BOOL, INT, STRING, packed arrays, etc.) are time-gated: the target is held until <code>object_interpolation_time / 2</code> of network time has elapsed since receive, then committed.</td>
</tr>
<tr>
<th>Interpolate Angle</th>
<td>Identical to <code>Interpolate</code>, except FLOAT uses <code>Math::lerp_angle</code> and VECTOR3 applies <code>lerp_angle</code> per axis (treats the vector as Euler radians). For all other types it behaves the same as <code>Interpolate</code>.</td>
</tr>
</tbody>
</table>


Per-property interpolation is decoupled from root smoothing.
It runs whether or not the root is networked, and whether `root_interpolation_mode` is `None`, `Exponential`, or `Forecast`.
The authority writes locally without delay; only non-authority instances shadow and lerp toward the target.
On spawn, interest-area re-enter, or teleport, all shadow targets snap directly to their nodes before lerping resumes.

> **Info**
> 
> **Typed arrays are excluded** from per-property interpolation. The Interpolate column on an `Array[T]` or `Array[ScriptClass]` row has no effect — element fields are written directly each tick. See [Typed Arrays](#typed-arrays). Composite expansion via the picker's "Add All" produces one row per primitive sub-field, and each of those rows interpolates normally.

The same exponential-decay function is exposed on the `Fusion` singleton for manual use, useful when you keep `Interpolate` set to `None` on a property and smooth a local copy yourself (for example a UI-side display value derived from the raw replicated state):

```gdscript
var smoothed_health: float = 0.0
var smoothed_yaw: float = 0.0

func _process(delta: float) -> void:
    smoothed_health = Fusion.interpolate_exponential(smoothed_health, health, 0.15, delta)
    smoothed_yaw    = Fusion.interpolate_exponential_angle(smoothed_yaw, target_yaw, 0.15, delta)
```

Both helpers accept FLOAT, VECTOR2, VECTOR3, and QUATERNION; other types return `target` and emit a warning. The `_angle` variant uses shortest-arc `lerp_angle` for FLOAT and per-axis `lerp_angle` for VECTOR3 (treats the vector as Euler radians); for VECTOR2 and QUATERNION it is identical to the plain function.

#### Runtime override

`set_property_interpolation` switches the mode and/or installs a custom callable for a single property at runtime, without modifying the saved `FusionReplicationConfig`:

```gdscript
replicator.set_property_interpolation(
    property: NodePath,
    mode: int,                       # FusionReplicationConfig.INTERPOLATE_NONE / LERP / ANGLE
    callable: Callable = Callable()  # empty Callable = no custom interpolator
) -> void
```

The callable replaces the default lerp / time-gated step and is invoked each frame with the current node value, the latest received target, the configured `object_interpolation_time`, and the frame `delta`:

```gdscript
# Typed signature (recommended): types must match the property's runtime Variant type.
func smooth_health(current: float, target: float, decay_time: float, delta: float) -> float:
    return lerp(current, target, 1.0 - exp(-delta / decay_time))

func _ready() -> void:
    replicator.set_property_interpolation(
        ^":health",
        FusionReplicationConfig.INTERPOLATE_LERP,
        smooth_health)

    # Switch mode without a callable
    replicator.set_property_interpolation(^":yaw", FusionReplicationConfig.INTERPOLATE_ANGLE)

    # Disable both for a property
    replicator.set_property_interpolation(^":health", FusionReplicationConfig.INTERPOLATE_NONE)
```

A registered callable forces the slot to shadow incoming values, even when `mode` is `None`. Calling `set_property_interpolation` with the default empty `Callable()` clears any previously installed callable for that slot. The override lives on the cached slot and is purely runtime; the saved replication config is never touched.

## Interest Management (AOI)

Interest management controls which objects each client receives updates for, reducing bandwidth in large worlds. Objects publish an interest key via `interest_mode` on the replicator; clients subscribe to keys via Fusion.

- **INTEREST_GLOBAL** (default) - visible to all clients
- **INTEREST_AREA** - spatial grid key auto-computed from position (cell size in Project Settings `fusion/interest_management/area_of_interest_cell_size`)
- **INTEREST_USER** - custom group key via `interest_key`
  Subscribe with one or more **[FusionInterestArea](../interest-area.md)** nodes (auto-manages grid subscriptions, typically following camera or player node) or manually:

```gdscript
Fusion.set_area_keys([[cell_key, 0]])   # area keys (refresh each frame)
Fusion.add_user_key(42)                  # user keys (persistent)
```

By default, an object entering / exiting interest will only emit enter / exit signals (`Fusion.interest_enter` / `interest_exit`).
If `interest_destroy_on_exit` is set to `true` on the replicator, the local object's node will be automatically freed when exiting interest, and re-spawned when entering interest again.

![FusionInterestArea - Node Inspector Settings](https://dev-doc.photonengine.com/docs/img/fusion-godot/v3/interest-area-inspector.png)

*FusionInterestArea - Node Inspector Settings*

## Key Properties

These inspector properties control replication behavior on each replicator instance.

- `root_path` (NodePath, `".."`) - node whose properties are synced
- `root_replication_mode` - `None` or `Auto`
- `root_interpolation_mode` - `None` / `Exponential` (non-physics roots) or `None` / `Forecast` (physics roots); default matches the root type
- `object_interpolation_time` (float, `0.150` s) - shared decay constant for `Exponential` root smoothing and per-property `Interpolate`
- `update_interval` (int, `1`) - server send interval in ticks
- `root_teleport_threshold` (float, `100.0`) - snap if error exceeds this
- `root_spring_stiffness` (float, `50.0`) / `root_spring_damping` (float, `10.0`) - physics correction tuning (visible only on physics replicators with non-blend correction mode)

![Replicator inspector](https://dev-doc.photonengine.com/docs/img/fusion-godot/v3/replicator-inspector.png)

*Replicator inspector*

## Signals

The replicator emits signals when authority changes or the network stomps state.

- `authority_changed(has_authority: bool)` - ownership changed
- `state_reset(info: FusionStateResetInfo)` - network reset this replicator's state. `info.reason` identifies the cause: `REASON_REMOTE_RECEIVED` (regular inbound sync), `REASON_PREDICTION_RESET` (client-server prediction rollback), or `REASON_STATE_OVERRIDE` (cloud stomped the authority). Not emitted on the local authority's outbound ticks.

See [Prediction and Input](prediction-and-input.md) for the input loop and prediction flow.


## Advanced: `reset_state()`

`reset_state()` resets the node to the current Fusion network buffer, bypassing smoothing. Emits `state_reset(REASON_REMOTE_RECEIVED)`.

Intended for **custom prediction** on replicated nodes - when your script advances the node's state manually and needs a lever to resync with the server buffer in between normal state-reset calls (which are still called normally).

```gdscript
@onready var replicator: FusionServerReplicator = $FusionServerReplicator

func _physics_process(delta: float) -> void:
    position += velocity * delta   # custom prediction

# Elsewhere, on whatever trigger your game defines:
replicator.reset_state()
```


For full control, combine with `root_interpolation_mode = None`. `reset_state()` itself bypasses smoothing, but leaving the mode on `Exponential` or `Forecast` means the root smoothing handler keeps applying toward the last-received target between your frames - typically fighting your custom extrapolation.
Per-property `Interpolate` is independent of the root mode: if a custom property is set to `Interpolate` or `Interpolate Angle`, disable it on that entry too when you need direct writes.

If your goal is just non-smoothed auto-replication on changed data (no custom prediction involved), setting `root_interpolation_mode = None` is enough. Every receive then snaps directly.
