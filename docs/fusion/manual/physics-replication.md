---
title: Physics Replication
url: https://dev-doc.photonengine.com/fusion-godot/v3-client-server/manual/physics-replication
product: fusion-godot
version: v3-client-server
language: en-us
description: "Sync physics in Godot multiplayer with Fusion: velocity-based forecasting and spring-damper correction keep remote rigid bodies smooth and jitter-free."
timestamp: 2026-07-21
---

# Physics Replication

Physics bodies are challenging to replicate because they move continuously under forces, collisions and gravity. Naively snapping a remote body to each received position causes visible jitter, especially at typical network update rates of 10-30 times per second.

Fusion solves this with velocity-based forecasting: remote clients predict where the body should be using its last known velocity, then a spring-damper system smoothly corrects any drift when the next server update arrives. The result is smooth motion on remote clients even under moderate packet loss or latency.

## Overview

Set `root_replication_mode` to `AUTO` on FusionSharedReplicator with a RigidBody2D/3D root. The replicator auto-detects the physics body and uses velocity-based forecast smoothing. Position, rotation, linear_velocity and angular_velocity are synced automatically - no manual property config needed.

## How Forecast Works

Between network updates the position is predicted using:

`predicted_pos = received_pos + velocity × time + 0.5 × gravity × time²`

A spring-damper system smoothly corrects the local state toward the predicted position, reducing perceived latency for fast-moving objects.

## Key Properties

These properties on FusionSharedReplicator control how physics corrections are applied on remote clients.

- `root_teleport_threshold` (float, `100.0`) - snap instantly if position error exceeds this
- `root_rotation_teleport_threshold` (float, `15.0`) - snap rotation if error exceeds this (degrees, 0 = disabled)
- `root_spring_stiffness` (float, `50.0`) - higher = stiffer correction
- `root_spring_damping` (float, `10.0`) - higher = less bounce
- `root_max_forecast_time` (float, `0.25`) - max seconds to predict ahead
- `root_correction_mode` - VELOCITY (light objects), FORCE (heavy objects, default) or BLEND (non-physical snapping)
- `root_blend_factor` (float, `0.1`) - weight for BLEND mode
- `root_forecast_gravity` (bool, `true`) - include gravity in prediction
- `sync_sleeping` (bool, `true`) - replicate physics sleep state

## Tuning Tips

Use these guidelines to diagnose and fix common physics replication artifacts.

- **Frequent teleporting**: increase `root_teleport_threshold`
- **Sluggish objects**: increase `root_spring_stiffness`, decrease `root_spring_damping`
- **Oscillation/bounce**: increase `root_spring_damping` (aim for `damping >= 2 × sqrt(stiffness)`)
- **Forecast overshoot**: reduce `root_max_forecast_time` or disable `root_forecast_gravity` for non-gravity objects

## Example (2D)

A RigidBody2D where only the authority client applies input - remote clients receive physics state automatically via the replicator.

```gdscript
extends RigidBody2D

const MOVE_FORCE := 600.0
@onready var sync: FusionSharedReplicator = $FusionSharedReplicator

func _physics_process(delta):
    if sync.has_authority():
        var dir = Input.get_axis("ui_left", "ui_right")
        if dir != 0:
            apply_central_force(Vector2(dir * MOVE_FORCE, 0))
        if Input.is_action_just_pressed("ui_accept"):
            apply_central_impulse(Vector2(0, -500))
```

Scene structure:

![Physics Player Scene Structure](https://dev-doc.photonengine.com/docs/img/fusion-godot/v3/physics-player-scene.png)

*Physics Player Scene Structure*

## Teleport

Force an instant snap to a new position (skips smoothing):

```gdscript
sync.teleport_2d(Vector2(400, 300), 0.0)                     # 2D (position, rotation)
sync.teleport_3d(Vector3(10, 0, 5), Vector3.ZERO)            # 3D (position, rotation)
sync.teleport_2d(Vector2(400, 300), deg_to_rad(90))           # 2D with rotation
```
