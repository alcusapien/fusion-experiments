---
title: RPCs - Basics
url: https://dev-doc.photonengine.com/fusion-godot/v3-client-server/manual/rpcs/basics
product: fusion-godot
version: v3-client-server
language: en-us
description: "How RPCs work in Godot multiplayer with Fusion: declaring remote procedure calls, targeting peers, broadcast vs object-targeted delivery, and GDScript examples."
timestamp: 2026-07-21
---

# RPCs - Basics

Replication keeps continuous state in sync - properties like position, health or score. But games also need one-shot events: a player fires a weapon, sends a chat message or triggers an ability. **Remote Procedure Calls (RPCs)** let you invoke a function on other clients to trigger these events.

RPCs are delivered once and not stored on the server. A player who joins after an RPC was sent will not receive it. That makes them a natural fit for ephemeral actions, and a poor fit for anything that must survive late joins - use replicated properties for those.

## Overview

All RPC methods live on the `Fusion` singleton. Receiving functions use Godot's standard `@rpc` annotation.

Fusion picks the delivery style automatically based on the node that owns the function being called:

- If that node has a replicator child (`FusionSharedReplicator` or `FusionServerReplicator`), the call is delivered to the matching networked object on remote clients - an **object-targeted RPC**.
- Otherwise, the call goes to every node previously registered as a **broadcast receiver** - a **broadcast RPC**.

For canonical patterns and worked examples, see [RPC Example Uses](example-uses.md).

## Three Calling Styles

Pick the style that matches who needs to receive the call: `rpc()` for everyone, `rpc_to()` for a role or special target, or `rpc_to_player()` for one specific player.

### `rpc()` - Send to All

```gdscript
Fusion.rpc(my_method, arg1, arg2)
```

Sends to every peer (equivalent to `rpc_to(Fusion.TARGET_ALL, ...)`).

### `rpc_to()` - Send to Enum Target

```gdscript
Fusion.rpc_to(Fusion.TARGET_MASTER, my_method, arg1)
Fusion.rpc_to(Fusion.TARGET_OWNER, my_method, arg1)   # object-targeted RPCs only
```

First argument is a `Fusion.RpcTarget` enum value (see below).

### `rpc_to_player()` - Send to Specific Player

```gdscript
Fusion.rpc_to_player(player_id, my_method, arg1, arg2)
```

Targets a specific player by their numeric ID (must be `> 0`).

## RpcTarget Enum

All constants are on `Fusion`:

| Constant | Description |
| --- | --- |
| `TARGET_ALL` | All peers (default) |
| `TARGET_MASTER` | Master client only - the player Photon designates as the room host |
| `TARGET_OWNER` | Object owner only - **object-targeted RPCs only**. Broadcast RPCs have no owner, so this target is rejected for them. |


> **Info**
> 
> `TARGET_PLUGIN` also exists for advanced server-side scripting via a custom Photon plugin. Most games will not need it.

## Object-Targeted RPCs

Object-targeted RPCs invoke a method on a specific networked object across clients. The method must belong to a node that has a replicator child - Fusion uses that replicator to route the call to the matching object on every other client.

```gdscript
@rpc("any_peer", "call_local")    # any_peer: any client may send; call_local: also runs locally on the sender
func take_damage(amount: int):
    health -= amount

func attack():
    # take_damage is a method on this node, and this node has a replicator child,
    # so Fusion routes the call through that replicator on remote clients.
    Fusion.rpc(take_damage, 10)

    # Same routing, but delivered only to the object's owner.
    Fusion.rpc_to(Fusion.TARGET_OWNER, take_damage, 10)
```

## Broadcast RPCs

Broadcast RPCs deliver a message to all clients without targeting a specific networked object. First register a **broadcast receiver** (any node that should handle incoming broadcast calls), then send through `Fusion`.

```gdscript
func _ready():
    Fusion.register_broadcast_receiver(self)

func _exit_tree():
    if Fusion:
        Fusion.unregister_broadcast_receiver(self)

@rpc("any_peer", "call_local")
func chat_message(sender: String, text: String):
    print("[%s]: %s" % [sender, text])

func send_chat(text: String):
    Fusion.rpc(chat_message, local_player_name, text)
```

> **Warning**
> 
> Always unregister broadcast receivers in `_exit_tree()`. If a registered node is freed without unregistering, Fusion still holds a dangling reference and will crash the next time a broadcast RPC arrives.

## @rpc Annotation

Godot's standard `@rpc` annotation configures who may send the call and whether it also executes locally on the sender.

```gdscript
@rpc("any_peer", "call_local")    # any client may send; also runs on the sender
@rpc("authority")                  # only the authority may send; default is "call_remote"
@rpc("any_peer", "call_remote")   # any client may send; only remotes execute
```

- **Mode**: `"authority"` checks `has_authority()` before sending (Fusion silently discards the call if the sender is not the authority). `"any_peer"` allows anyone to send.
- **Sync**: `"call_remote"` (default) sends to remotes only. `"call_local"` also executes on the sender immediately after sending - useful when you want instant local feedback without a separate code path.

In Client-Server, the "authority" is always the simulation server. See [Prediction and Input](../replication/prediction-and-input.md) for how authority works on the input loop.


## Supported Argument Types

Fusion RPCs accept most Godot built-in types and networked node references:

- `bool`, `int`, `float`, `String`
- `Vector2`, `Vector3`, `Vector4`, `Quaternion`, `Color`
- `PackedByteArray`, `Array`, `Dictionary`
- Networked `Node` references (automatically encoded for network transmission)

> **Info**
> 
> A `Node` reference may arrive as `null` if the target was despawned before the RPC reached the remote client. Always null-check `Node` arguments before using them.

## Next

See [RPC Example Uses](example-uses.md) for canonical patterns and worked examples.
