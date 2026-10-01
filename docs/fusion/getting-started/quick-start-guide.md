---
title: Quick Start Guide (Client-Server)
url: https://dev-doc.photonengine.com/fusion-godot/v3-client-server/getting-started/quick-start-guide
product: fusion-godot
version: v3-client-server
language: en-us
description: "Build server-authoritative multiplayer in Godot 4 with Fusion: host authority, input queuing, and client prediction in a 10-step guide to synced movement."
timestamp: 2026-07-21
---

# Quick Start Guide (Client-Server)

> **Info**
> 
> This is the **Client-Server** quick start. Looking for the [Shared-Authority Quick Start](https://dev-doc.photonengine.com/fusion-godot/v3-shared-authority/getting-started/quick-start-guide.md)? Not sure which to pick? See [Choose a Topology](choose-topology.md).

## Introduction

This guide builds a Client-Server multiplayer scene where the host has full authority over game state and clients send input for server-side execution. By the end, two instances will move 3D characters around a shared room using the input queue and prediction flow.

In Client-Server topology, one player acts as the **host** (also called the simulation server). The host runs game logic and decides what happens. Other clients send their input to the host and predict the result locally for responsive feel. The Photon Cloud handles state distribution to all clients.

Requirements: Godot 4.6 editor, basic GDScript knowledge and the Fusion addon installed.

## Step 1 - Prerequisites

1. Create or log on to an account at [dashboard.photonengine.com](https://dev-dashboard.photonengine.com).
2. Click **Create a New App**, select **Fusion** as the SDK and Version 3.
3. Copy the **App ID** from the app detail page.
4. Download the Fusion addon from [SDK Download](sdk-download.md) and copy the `fusion/` folder into `addons/` in your Godot project root.
5. Reopen the project, open **Project Settings** and search for **Fusion**. Paste the App ID into `fusion/connection/app_id`, and set `fusion/simulation/mode` to **Client Server** - this enables Client-Server topology (the default is Shared). Game code can query the active mode at runtime via `Fusion.get_simulation_mode()`.

## Step 2 - Main Scene Setup

Create a main scene with a Node3D root. Add a Camera3D (orthographic works well for testing), a DirectionalLight3D, a floor StaticBody3D with a collision shape and mesh, a FusionSpawner and an empty Node3D named `Characters` to hold spawned objects. Set the FusionSpawner's `spawn_path` to `../Characters`.

![Main Scene Structure](https://dev-doc.photonengine.com/docs/img/fusion-godot/v3/authority-3d-main-scene.png)

*Main Scene Structure*

## Step 3 - Character Scene with FusionServerReplicator

Create a new scene with a CharacterBody3D root. Add a CollisionShape3D (capsule), a MeshInstance3D (capsule) and a **FusionServerReplicator** child node. In the inspector, set the replicator's `owner_mode` to `PLAYER_PREDICTED` and `root_replication_mode` to `AUTO`. Save the scene as `authority_character_3d.tscn`.

![Character Scene Structure](https://dev-doc.photonengine.com/docs/img/fusion-godot/v3/authority-3d-character-scene.png)

*Character Scene Structure*

## Step 4 - How the Server Starts

Client-Server topology has no separate server executable to launch. The simulation server is just a regular Fusion peer - whichever peer **creates** the room becomes the server, and every peer that **joins** an existing room is a client.

Two pieces make this work:

- **`fusion/simulation/mode = Client Server`** (set in Step 1). Fusion applies the Client-Server authority model only when this setting is on. With Shared mode, the same room would use Shared-Authority instead.
- **Master client = simulation server**. Photon designates the room creator as the master client, and Fusion treats that peer as the authority for all networked state.

The same code supports two deployment models without changes:

- **Client-Host**: a normal game instance creates the room and also plays. One player's machine runs both the simulation and their own character.
- **Dedicated-Server**: a headless Godot build creates the room without rendering or local input. Every peer that joins is a client.

In the steps below, `Fusion.is_master_client()` is how you distinguish "I am the simulation server" from "I am a client" at runtime.

## Step 5 - Connect and Join

Attach a script to the main scene root. The connection flow is: initialize Fusion from Project Settings, connect to the Photon Cloud and join or create a room when the connection succeeds. A room is a shared session where players sync objects and exchange RPCs.

```gdscript
extends Node3D

const CharacterScene = preload("res://authority_character_3d.tscn")

@onready var spawner: FusionSpawner = $FusionSpawner

func _ready():
    Fusion.room_joined.connect(_on_room_joined)
    Fusion.register_broadcast_receiver(self)  # enables this node to receive broadcast RPCs
    spawner.add_spawnable_scene(CharacterScene)

    Fusion.connect_to_photon.call_deferred("user_%d" % randi())
    Fusion.connected_to_photon.connect(func():
        Fusion.join_or_create_room()
    )
```

## Step 6 - Spawn Request Pattern

In Client-Server, only the master client spawns objects. The master client is the first player to create or join the room - Photon designates them as the host who runs the simulation. When a non-master client joins, it sends a broadcast RPC (a global message delivered to all registered receivers) requesting a character. The master receives the request, spawns the character and assigns input authority to the requesting player. The master also spawns its own character on room join.

```gdscript
func _on_room_joined():
    if Fusion.is_master_client():
        _spawn_character(Fusion.get_local_player_id())
    else:
        Fusion.rpc(request_spawn)

@rpc("any_peer", "call_local")
func request_spawn():
    if not Fusion.is_master_client():
        return
    var sender_id = Fusion.get_rpc_sender()
    _spawn_character(sender_id)

func _spawn_character(player_id: int):
    var character = spawner.spawn()
    character.position = Vector3(randf_range(-4, 4), 1.0, randf_range(-4, 4))
    character.get_node("FusionServerReplicator").set_input_authority(player_id)
```

## Step 7 - Input Packing and Queuing

On the character script, the input-authority client reads keyboard input each frame and packs it into a byte buffer. The buffer is sent to the server via `queue_input()`. Only the client with input authority should create input.

```gdscript
extends CharacterBody3D

const SPEED := 5.0
const GRAVITY := -20.0

@onready var replicator: FusionServerReplicator = $FusionServerReplicator
var _tick: int = 0

func _ready():
    replicator.on_process_input.connect(process_input)

func _create_input() -> PackedByteArray:
    var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var buf = PackedByteArray()
    buf.resize(12)
    buf.encode_float(0, dir.x)
    buf.encode_float(4, dir.y)
    buf.encode_u32(8, _tick)
    _tick += 1
    return buf

func _physics_process(delta):
    if replicator.has_input_authority():
        replicator.queue_input(delta, _create_input())
    replicator.process_input_queue(delta)  # runs on all peers: prediction on input-authority, authoritative on server, no-op on remotes
```

## Step 8 - Input Execution and Movement

When `process_input_queue()` is called, Fusion emits the `on_process_input` signal with the input payload. This callback runs on both the input-authority client (as a prediction) and on the server (as the authoritative execution). The same movement code runs on both sides.

```gdscript
# is_new is true the first time this input runs. It is false during re-simulation
# after a prediction reset. Guard one-shot effects (sounds, particles) behind is_new.
func process_input(tick: int, delta_time: float, payload: PackedByteArray, is_new: bool):
    var dir_x = payload.decode_float(0)
    var dir_z = payload.decode_float(4)
    velocity = Vector3(dir_x, 0.0, dir_z) * SPEED
    velocity.y += GRAVITY * delta_time
    move_and_slide()
```

> **Info: What about other players?**
> 
> Players who do not have input authority for a character simply receive the replicated position, rotation and velocity from the server. The FusionServerReplicator applies smoothing automatically, so remote characters appear to move smoothly even though updates arrive roughly 30 times per second. `process_input_queue()` is a no-op on these remote clients.

## Step 9 - Test with Multiple Instances

Set **Debug > Customize Run Instances > Enable Multiple Instances** to 2 and press Play. The first instance becomes the master and spawns its own character. The second instance joins and sends a spawn request via RPC. Both instances should see two characters - each controlled by its respective player.

## Step 10 - Custom Properties with Prediction

Custom gameplay properties (health, score, name) are added via the FusionServerReplicator's bottom panel in the editor. Select the FusionServerReplicator node in your character scene - the bottom panel (below the viewport) shows the Fusion Replication Editor. Click **Add Property** to register a property from the scene tree for network synchronization.

For example, add a `:score` property from the root node. On the input-authority client, set predicted values immediately for responsive feel. If the server produces a different authoritative value, a prediction reset corrects the client automatically.

```gdscript
var score: int = 0

# In process_input - both client (prediction) and server (authoritative) run this
func process_input(tick: int, delta_time: float, payload: PackedByteArray, is_new: bool):
    # ... movement code ...
    if collected_coin:
        score += 1
```

See [Syncing Properties](../manual/replication/syncing-properties.md) for the full custom properties reference.

## Next Steps

- [Prediction and Input](../manual/replication/prediction-and-input.md) - Full input loop, prediction and authority reference
- [Choose a Topology](choose-topology.md) - Understand the tradeoffs
- [Connection](../manual/connection.md) - Full connection lifecycle and room options
- [Spawning](../manual/spawning.md) - Spawn configuration and sub-objects
- [RPCs](../manual/rpcs/basics.md) - Object and broadcast RPCs

## Complete Scripts

The full scripts assembled from the steps above.

**main.gd** (attach to main scene root):

```gdscript
extends Node3D

const CharacterScene = preload("res://authority_character_3d.tscn")

@onready var spawner: FusionSpawner = $FusionSpawner

func _ready():
    Fusion.room_joined.connect(_on_room_joined)
    Fusion.register_broadcast_receiver(self)
    spawner.add_spawnable_scene(CharacterScene)

    Fusion.connect_to_photon.call_deferred("user_%d" % randi())
    Fusion.connected_to_photon.connect(func():
        Fusion.join_or_create_room()
    )

func _on_room_joined():
    if Fusion.is_master_client():
        _spawn_character(Fusion.get_local_player_id())
    else:
        Fusion.rpc(request_spawn)

@rpc("any_peer", "call_local")
func request_spawn():
    if not Fusion.is_master_client():
        return
    var sender_id = Fusion.get_rpc_sender()
    _spawn_character(sender_id)

func _spawn_character(player_id: int):
    var character = spawner.spawn()
    character.position = Vector3(randf_range(-4, 4), 1.0, randf_range(-4, 4))
    character.get_node("FusionServerReplicator").set_input_authority(player_id)

func _exit_tree():
    if Fusion:
        Fusion.unregister_broadcast_receiver(self)
```

**authority_character_3d.gd** (attach to CharacterBody3D root):

```gdscript
extends CharacterBody3D

const SPEED := 5.0
const GRAVITY := -20.0

@onready var replicator: FusionServerReplicator = $FusionServerReplicator
var _tick: int = 0

func _ready():
    replicator.on_process_input.connect(process_input)

func _create_input() -> PackedByteArray:
    var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var buf = PackedByteArray()
    buf.resize(12)
    buf.encode_float(0, dir.x)
    buf.encode_float(4, dir.y)
    buf.encode_u32(8, _tick)
    _tick += 1
    return buf

func _physics_process(delta):
    if replicator.has_input_authority():
        replicator.queue_input(delta, _create_input())
    replicator.process_input_queue(delta)

func process_input(tick: int, delta_time: float, payload: PackedByteArray, is_new: bool):
    var dir_x = payload.decode_float(0)
    var dir_z = payload.decode_float(4)
    velocity = Vector3(dir_x, 0.0, dir_z) * SPEED
    velocity.y += GRAVITY * delta_time
    move_and_slide()
```
