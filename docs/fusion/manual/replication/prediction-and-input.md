---
title: Prediction and Input
url: https://dev-doc.photonengine.com/fusion-godot/v3-client-server/manual/replication/prediction-and-input
product: fusion-godot
version: v3-client-server
language: en-us
description: "Implement client-side prediction in Godot multiplayer: input handling, server reconciliation, and lag compensation with Fusion's tick-based simulation."
timestamp: 2026-07-21
---

# Prediction and Input

## Overview

In Client-Server topology, a simulation server (host or dedicated server) runs game logic and validates all state changes. Clients do not write properties directly. Instead, they pack input into a buffer, send it to the simulation server and predict the result locally. The simulation server executes and writes the authoritative state. The Photon Cloud still handles state distribution, AOI filtering and late join snapshots - the simulation server focuses on gameplay. When a client's prediction diverges from the authoritative state, a correction is applied.

## The Mental Model

In Shared-Authority, each client thinks: "I own my objects and I write their state directly." In Client-Server, each client thinks: "I suggest input, the authority decides what happens, and I predict locally until the authority confirms." The server is always the source of truth - client state is a prediction that may be corrected at any time.

## FusionServerReplicator

FusionServerReplicator handles property sync and the Client-Server input loop for networked objects: custom properties, smoothing, AOI, root replication modes, plus input queuing, input execution, input authority assignment and prediction signals. Use it on any object that participates in the Client-Server prediction flow.

## PLAYER_PREDICTED Owner Mode

Set the replicator's `owner_mode` to `PLAYER_PREDICTED` in the inspector. This mode enables input authority assignment via `set_input_authority()` and activates the prediction flow where the input-authority client predicts locally while the server executes authoritatively. Pass a `pre_spawn_function` callback to `spawner.spawn()` to assign authority before the spawned scene's `_ready()` runs, so the assignment is observable in `_ready()`.

## The Input Loop

### Input Authority API

Input authority determines which client sends input for this object. It is separate from state authority (which always belongs to the server). After spawning an object, the master assigns input authority to the requesting player.

- `has_input_authority()` - `true` on the client that sends input for this object
- `has_authority()` - `true` on the server/host (the state authority)
- `get_input_authority()` - returns the player ID that has input authority
- `set_input_authority(player_id)` - assigns input authority (master only)

> **Info**
> 
> On the host (the player acting as both client and server), `has_authority()` is `true` for all objects and `has_input_authority()` is also `true` for the host's own character. When writing code that branches on these flags, make sure your logic handles this dual-role case.

### Packing Input Payloads

Each frame, the input-authority client reads player input and encodes it into a `PackedByteArray`. The buffer is passed to `queue_input(delta, buffer)` which sends it to the server. The buffer format is up to you - encode whatever your game needs (direction, actions, tick counter).

```gdscript
func _create_input() -> PackedByteArray:
    var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var buf = PackedByteArray()
    buf.resize(12)
    buf.encode_float(0, dir.x)
    buf.encode_float(4, dir.y)
    buf.encode_u32(8, _tick)
    _tick += 1
    return buf
```

### Queue and Execute Flow

Call `process_input_queue(delta)` every frame (or physics frame) on all peers. On the input-authority client, it fires `on_process_input` with the locally queued input (prediction). On the server, it fires with the received input from the input-authority client (authoritative execution). On remote proxies (neither server nor input authority), `process_input_queue()` is a no-op - the object's state comes from replication. Write your movement logic once in the `on_process_input` callback and it runs on both the predicting client and the server.

```gdscript
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

## Signals

- `on_process_input(tick: int, delta_time: float, payload: PackedByteArray, is_new: bool)` - fired by `process_input_queue()` with the next input from the queue. `is_new` is `true` the first time this input is executed (on both client and server). It is `false` during re-simulation, which occurs after a prediction reset when the client re-executes buffered inputs to rebuild predicted state. Guard one-shot side effects (sounds, particles, UI updates) behind `is_new` to prevent duplicates.
- `state_reset(info: FusionStateResetInfo)` - fired whenever the network stomps this replicator's state. When `info.reason == FusionStateResetInfo.REASON_PREDICTION_RESET`, the server's authoritative state differed from the client's prediction and a correction was applied.

## Prediction Reset

When the server processes input and produces a state that differs from what the client predicted, the `state_reset` signal fires with `info.reason == REASON_PREDICTION_RESET`. The client's replicated properties are corrected to match the server. Connect to this signal (branching on the reason) if you need to handle visual or audio artifacts caused by corrections (for example, snapping a particle effect to the corrected position).

> **Warning**
> 
> Only replicated properties are corrected during a prediction reset. Local variables (non-replicated state like animation progress, jump counters or cooldown timers) are NOT rolled back. If your gameplay logic depends on local state that should be consistent with replicated state, you must manually reset it in the `state_reset` handler when `info.reason == REASON_PREDICTION_RESET`.

## Queue Monitoring

Monitor the input queue on the server side to detect starvation (queue empty, causing hitches) or buildup (queue growing, causing increasing latency).

- `get_input_queue_count()` - number of inputs currently queued on the server
- `get_input_queue_delta_time()` - delta time of the last queued input

These are useful for diagnostics labels during development. The demo projects display min/current/max queue count over a rolling 0.5-second window.

## Debugging Tips

- **Color-code authority**: set the object's color based on `has_input_authority()` (green), `has_authority()` (cyan) or neither (white) so you can immediately see who owns what.
- **Display queue stats**: show `get_input_queue_count()` and `get_input_queue_delta_time()` in a label to catch queue starvation or buildup early.
- **Watch for tick gaps**: include a tick counter in your input buffer and log when the received tick skips - this indicates dropped input.
- **Network Inspector**: use the built-in Fusion Network debugger tab (Debugger > Fusion Network) to see per-object bandwidth, RTT, authority and word count in real time.
