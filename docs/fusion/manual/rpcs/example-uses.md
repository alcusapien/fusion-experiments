---
title: RPCs - Example Uses
url: https://dev-doc.photonengine.com/fusion-godot/v3-client-server/manual/rpcs/example-uses
product: fusion-godot
version: v3-client-server
language: en-us
description: "Copy-paste RPC examples for Godot multiplayer with Fusion: GDScript patterns for text chat, one-shot effects, and sending events to the right clients."
timestamp: 2026-07-21
---

# RPCs - Example Uses

RPCs are how you trigger ephemeral events across clients. The patterns below are the ones you will reach for most often. This page assumes familiarity with [RPC Basics](basics.md).

## Client → Server Requests

Clients do not own game state - the simulation server does. So when a client wants something to happen, it packages intent as a broadcast RPC and lets the master client (the server) validate and act on it.

Typical requests:

- **Spawn a character with a chosen payload** - loadout, class, cosmetics. The master receives the request, validates it and spawns on behalf of the requester.
- **Loot a nearby pickable** - the client that walked into range sends a loot request; the server checks proximity and availability, then applies the effect.

The full spawn-request pattern with working code is already documented in the [Quick Start Guide](../../getting-started/quick-start-guide.md) (Step 5) - use that as your template.

## Server → All Clients Notifications

RPCs are not cached. A player who joins after the call will not see it. That makes RPCs a good fit for short-lived notifications that late joiners do not need to know about:

- A hit flash or kill-feed entry
- A round-start siren or countdown tick
- A one-shot VFX burst triggered by a server-side event

Anything that needs to survive late joins belongs in a replicated property instead - a late joiner will receive the latest value on spawn. Use RPCs only for the ephemeral half.


## Common Patterns

### Text Chat

Chat is a textbook fit for broadcast RPCs: one client sends, everyone receives, nothing needs to survive late joins.

```gdscript
func _ready():
    Fusion.register_broadcast_receiver(self)

func _exit_tree():
    if Fusion:
        Fusion.unregister_broadcast_receiver(self)

@rpc("any_peer", "call_local")
func chat_message(sender: String, text: String):
    $ChatPanel.append_line("[%s]: %s" % [sender, text])

func send_chat(text: String):
    Fusion.rpc(chat_message, local_player_name, text)
```

> **Info**
> 
> For production-grade chat, consider [Photon Chat](https://www.photonengine.com/chat) - a separate Photon product with turnkey features like AI moderation and word filtering via compatible third-party integrations, out of scope for raw RPCs.

### UI and One-Shot Effects

Short-lived effects - a sound, a particle burst, a screen flash, a toast - map naturally to RPCs. Use `"call_local"` in the `@rpc` annotation when the sender should also see the effect without a separate code path.

## See Also

- [RPC Basics](basics.md) - the API and routing rules
- [Prediction and Input](../replication/prediction-and-input.md) - the input loop that replaces most damage/action RPCs
- [Quick Start Guide](../../getting-started/quick-start-guide.md) - Step 5 has the full spawn-request pattern
- [Photon Chat](https://www.photonengine.com/chat) - managed chat product
