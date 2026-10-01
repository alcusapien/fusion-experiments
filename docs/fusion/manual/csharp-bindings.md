---
title: "C# Bindings"
url: https://dev-doc.photonengine.com/fusion-godot/v3-client-server/manual/csharp-bindings
product: fusion-godot
version: v3-client-server
language: en-us
description: "Use Godot C# with the Fusion SDK: static Fusion class, signals as C# events, FusionServerReplicator wrappers, and [Rpc] attributes. Port from GDScript fast."
timestamp: 2026-07-21
---

# C# Bindings

The Fusion Godot SDK comes with a thin binding layer to support programming using C#.
It contains a static `Fusion` class, typed wrapper classes for every Fusion node and handle, C# events for signals, and enums that mirror the native constants.

This page is for developers already familiar with Fusion Godot's GDScript workflow (see the [Quick Start Guide](../getting-started/quick-start-guide.md)), and will only focus on what is *different* in C#.
The main concepts (connection, spawning, replication, RPCs) are identical - only the syntax has changed to fit C#'s coding style.

## The Fusion Singleton

In GDScript, `Fusion` is a globally registered autoload you call directly.
In C#, `Fusion` is a **static class** in the `FusionGodot` namespace that forwards to the same native singleton.

All method names have changed from being `snake_case` to `PascalCase`:

**C#**

```csharp
Fusion.ConnectToPhoton("user_1");
Fusion.JoinOrCreateRoom("test-room");
int id = Fusion.GetLocalPlayerId();
```


**GDScript**

```gdscript
Fusion.connect_to_photon("user_1")
Fusion.join_or_create_room("test-room")
var id = Fusion.get_local_player_id()
```




## Signals

In C#, Fusion Godot's signals are exposed as standard C# events. As such, they can be subscribed to using `+=` and unsubscribed from using `-=`.

**C#**

```csharp
public override void _Ready()
{
    // Connect via method group
    Fusion.PlayerJoined += OnPlayerJoined;
    
    // Connect via anonymous function
    Fusion.ConnectionFailed += err => GD.PrintErr($"connection failed: {err}");
}

private void OnPlayerJoined(int id, string userId)
{
    GD.Print($"player joined: {id}");
}
```


**GDScript**

```gdscript
func _ready():
    # Connect via Callable
    Fusion.player_joined.connect(_on_player_joined)
    
    # Connect via anonymous function
    Fusion.connection_failed.connect(func(err): printerr("connection failed: ", err))


func _on_player_joined(id: int, user_id: String):
    print("player joined: ", id)
```




The same pattern applies to node wrappers.
Replicators, spawners, and other handles expose their signals as C# events as well.

## Casting Nodes to Wrappers

Fusion nodes (`FusionSpawner`, `FusionReplicator`, `FusionSharedReplicator`, `FusionServerReplicator`, `FusionInterestArea`) are GDExtension classes. As such, using `GetNode<T>()` for Fusion's nodes is not possible.

To cast a `Node` instance to a Fusion type, use the `AsX()` extension method.
There is also an equivalent of `GetNode<T>(NodePath)` to retrieve a child node, `GetX(NodePath)`:

| Desired Node Type | AsX() Method | GetX() Method |
| --- | ---- | ----- |
| FusionReplicator | `node.AsReplicator()` | `node.GetReplicator(NodePath)` |
| FusionSharedReplicator | `node.AsSharedReplicator()` | `node.GetSharedReplicator(NodePath)` |
| FusionServerReplicator | `node.AsServerReplicator()` | `node.GetServerReplicator(NodePath)` |
| FusionSpawner | `node.AsSpawner()` | `node.GetSpawner(NodePath)` |
| FusionInterestArea | `node.AsInterestArea()` | `node.GetInterestArea(NodePath)` |


**C#**

```csharp
private FusionSpawner _spawner;
private FusionServerReplicator _rep;

public override void _Ready()
{
    // Via AsX() casting
    _spawner = GetNode("FusionSpawner").AsSpawner();
    _rep = GetNode("FusionReplicator").AsServerReplicator();

    // Via GetX() helper
    _spawner = this.GetSpawner("FusionSpawner");
    _rep = this.GetServerReplicator("FusionReplicator");
}
```


**GDScript**

```gdscript
@onready var _spawner: FusionSpawner = $FusionSpawner
@onready var _rep: FusionServerReplicator = $FusionReplicator
```




> **Info**
> 
> While creating a wrapper via `GetX()`/`AsX()` is cheap, it is best to avoid re-wrapping a node repeatedly to avoid unnecessary GC pressure.
> Prefer caching the wrapper in a field (as above) and reusing it whenever possible.

## RPCs

RPCs work the same way as in GDScript: receiving methods use Godot's standard RPC annotation, and calls are sent through the `Fusion` singleton.

Two things change in C#:

- The receiving method uses the C# `[Rpc]` attribute instead of the GDScript `@rpc` annotation.
- The sending call can take either Node + StringName, **or** a C# delegate.

**C#**

```csharp
[Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = true)]
public void TakeDamage(int amount)
{
    _health -= amount;
}

public void Attack()
{
    // Option 1: via delegate
    Fusion.Rpc(TakeDamage, 10);

    // Option 2: via Node + StringName
    Fusion.Rpc(this, "TakeDamage", 10);
}
```


**GDScript**

```gdscript
@rpc("any_peer", "call_local")
func take_damage(amount: int):
    health -= amount


func attack():
    Fusion.rpc(take_damage, 10)
```




> **Info**
> 
> When calling an RPC by Node + StringName, consider using the automatically generated MethodName class (e.g. `Player.MethodName.TakeDamage`) to avoid the performance impact of a String to StringName conversion.

### RPC Context And Results

Inside an RPC handler, the RPC context can be obtained exactly the same as in GDScript:

**C#**

```csharp
[Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = true)]
public void ChatMessage(string text)
{
    FusionRpcInfo info = Fusion.GetRpcInfo(); // Can be null if not executing as an RPC
    GD.Print($"{info.Sender} says '{text}' to {info.Target}");
}
```


**GDScript**

```gdscript
@rpc("any_peer", "call_local")
func chat_message(text: string):
    var info := Fusion.get_rpc_info()
    print(info.sender, " says '", text, "' to ", info.target)
```




RPC calls return a `FusionRpcResult` handle for optional failure handling, chainable via `OnFail`:

**C#**

```csharp
Fusion.Rpc(TakeDamage, 10)
      .OnFail(Callable.From(() => GD.Print("RPC failed")), ttl: 2.0f);
```


**GDScript**

```gdscript
Fusion.rpc(take_damage, 10) \
      .on_fail(func(): print("RPC failed"), 2.0)
```




### Broadcast RPCs

Just like in GDScript, Broadcast RPC receivers must be registered and unregistered via `Fusion.RegisterBroadcastReceiver(this)` / `Fusion.UnregisterBroadcastReceiver(this)`.

## The Escape Hatch

If a native member is not surfaced by the binding (or you want to call something the typed API does not cover), you can obtain the native object for a given Fusion type directly using the `Self` member:

- `wrapper.Self` - the underlying `GodotObject`, for raw `Call(...)` / `Connect(...)`.
- `wrapper.IsValid` - `true` while the wrapped native instance is still alive.
- `Fusion.Singleton` - the native `Fusion` singleton object.

```csharp
// Anything the typed surface omits is still reachable:
_serverReplicator.Self.Call("some_native_method", arg);
```

## Quick Start Guide Example

The two scripts below are the C# equivalent of the [Quick Start Guide (Client Server)](../getting-started/quick-start-guide.md)'s main scene and player scene.

`Main.cs` - connect, join, spawn:

```csharp
using Godot;
using FusionGodot;

public partial class Main : Node3D
{
    private FusionSpawner _spawner;

    public override void _Ready()
    {
        Fusion.RoomJoined += OnRoomJoined;
        _spawner = this.GetSpawner("FusionSpawner");
        Fusion.RegisterBroadcastReceiver(this);
        _spawner.AddSpawnableScene(
            GD.Load<PackedScene>("res://authority_character_3d.tscn"));

        Callable.From(() => Fusion.ConnectToPhoton("user_" + GD.Randi()))
            .CallDeferred();

        Fusion.ConnectedToPhoton += () => Fusion.JoinOrCreateRoom("room");
    }

    private void OnRoomJoined()
    {
        if (Fusion.IsMasterClient())
            SpawnCharacter(Fusion.GetLocalPlayerId());
        else
            Fusion.Rpc(RequestSpawn);
    }

    [Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = true)]
    public void RequestSpawn()
    {
        if (!Fusion.IsMasterClient()) return;
        SpawnCharacter(Fusion.GetRpcSender());
    }

    private void SpawnCharacter(int playerId)
    {
        var character = _spawner.Spawn();
        ((Node3D)character).Position = new Vector3(
            (float)GD.RandRange(-4.0, 4.0), 1.0f, (float)GD.RandRange(-4.0, 4.0));

        character.GetServerReplicator("FusionServerReplicator").InputAuthority = playerId;
    }

    public override void _ExitTree()
    {
        if (IsInstanceValid(Fusion.Singleton))
            Fusion.UnregisterBroadcastReceiver(this);
    }
}
```

`AuthorityCharacter3d.cs` - authority-gated movement:

```csharp
using Godot;
using FusionGodot;
using System;

public partial class AuthorityCharacter3d : CharacterBody3D
{
    private const float Speed = 5f;
    private const float Gravity = -20f;

    private FusionServerReplicator _replicator;
    private int _tick;

    public override void _Ready()
    {
        _replicator = this.GetServerReplicator("FusionServerReplicator");
        _replicator.OnProcessInput += OnProcessInput;
    }

    private byte[] CreateInput()
    {
        Vector2 dir = Input.GetVector("ui_left", "ui_right", "ui_up", "ui_down");
        byte[] buf = new byte[12];
        Array.Copy(BitConverter.GetBytes(dir.X), 0, buf, 0, 4);
        Array.Copy(BitConverter.GetBytes(dir.Y), 0, buf, 4, 4);
        Array.Copy(BitConverter.GetBytes(_tick), 0, buf, 8, 4);
        _tick++;
        return buf;
    }

    public override void _PhysicsProcess(double delta)
    {
        if (_replicator.HasInputAuthority())
            _replicator.QueueInput((float)delta, CreateInput());

        _replicator.ProcessInputQueue((float)delta);
    }

    private void OnProcessInput(int tick, float deltaTime, byte[] payload, bool isNew)
    {
        float dirX = BitConverter.ToSingle(payload, 0);
        float dirY = BitConverter.ToSingle(payload, 4);
        Vector3 newVelocity = new Vector3(dirX, 0, dirY) * Speed;
        newVelocity.Y = Velocity.Y + Gravity * deltaTime;
        Velocity = newVelocity;
        MoveAndSlide();
    }
}
```
