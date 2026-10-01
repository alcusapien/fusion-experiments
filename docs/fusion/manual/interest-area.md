---
title: FusionInterestArea
url: https://dev-doc.photonengine.com/fusion-godot/v3-client-server/manual/interest-area
product: fusion-godot
version: v3-client-server
language: en-us
description: "Scale your Godot multiplayer game with interest areas: replicate only what each player can see to cut bandwidth in large worlds and MMO-style games."
timestamp: 2026-07-21
---

# FusionInterestArea

In a large world, sending every object's state to every client wastes bandwidth and exposes information players should not have. Area of Interest (AOI) solves this by letting each client subscribe to a spatial region - only objects within that region are replicated to them. Objects outside the subscription area are invisible to the client, reducing both bandwidth and the surface for cheating.

Fusion implements AOI through a grid system: the world is divided into fixed-size cells and each client subscribes to a set of cells around its position. Objects publish which cell they belong to, and the server matches object cells against player subscriptions to decide what to send.

## Overview

FusionInterestArea auto-manages grid subscriptions for Area of Interest (AOI). Add it as a child node and it will compute which grid cells to subscribe to each frame based on its shape, size and the position of the target node.

For an overview of interest modes, see [Replication - Interest Management](https://dev-doc.photonengine.com/fusion-godot/v3-client-server/manual/replication#interest-management-aoi).

## Properties

These properties control the shape, size and behavior of the subscription area.

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `shape` | Shape | `SQUARE` | Subscription area shape |
| `orientation` | Orientation | `3D_XZ` | Which plane to project onto for cell computation |
| `grid_size` | int | `5` | Side length in cells (Square only, odd values: 1–21) |
| `radius` | float | `5.0` | Radius in cells (Circle and Cone only) |
| `fov_angle` | float | `90.0` | Field-of-view angle in degrees (Cone only) |
| `base_send_rate` | int | `1` | Send-rate override for center cells (0 = use server default) |
| `decay_mode` | DecayMode | `DOUBLING` | How send rate increases with distance from center |
| `target_path` | NodePath | `".."` | Node whose position drives cell computation |
| `enabled` | bool | `true` | Toggle subscriptions on/off at runtime |


### Debug Properties

Enable debug visualization to see subscribed cells as an overlay in the viewport.

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `debug_draw` | bool | `false` | Draw subscribed cells as overlay |
| `debug_labels` | DebugLabels | `NONE` | Label content shown on debug cells |
| `debug_gradient` | Gradient | `null` | Color gradient mapped to send rate (low → high) |


## Enums

### Shape

The subscription area shape determines how cells are selected around the target position.

| Value | Description |
| --- | --- |
| `SQUARE` | grid_size × grid_size rectangular area |
| `CIRCLE` | Radius-based, skips corner cells outside the circle |
| `CONE` | Directional FOV in the view direction |


### Orientation

Orientation selects which 2D plane the grid is projected onto.

| Value | Description |
| --- | --- |
| `2D` | X,Y plane (for Node2D scenes) |
| `3D_XZ` | X,Z horizontal plane (default for 3D) |
| `3D_XY` | X,Y vertical plane in 3D |


### DecayMode

Decay mode controls how the server send rate decreases for cells farther from center, saving bandwidth at the edges.

| Value | Description |
| --- | --- |
| `FLAT` | Same send rate for all cells |
| `DOUBLING` | Doubles per ring beyond ring 1 |
| `LINEAR` | base + ring × step |


### DebugLabels

Debug labels configure what information is displayed on each cell in the debug overlay.

| Value | Description |
| --- | --- |
| `NONE` | No labels |
| `PRIORITY` | Show computed priority value |
| `CELL_AND_PRIORITY` | Show cell ID and priority |


## Usage

Add a FusionInterestArea as a sibling of the FusionSharedReplicator and configure its shape and radius in the inspector or via code.

```gdscript
# Scene tree:
# Player (CharacterBody3D)
# +-- Camera3D
# +-- FusionSharedReplicator
# +-- FusionInterestArea

@onready var interest: FusionInterestArea = $FusionInterestArea

func _ready():
    interest.shape = FusionInterestArea.SHAPE_CIRCLE
    interest.radius = 8.0
    interest.decay_mode = FusionInterestArea.DECAY_DOUBLING
```

> **Info**
> 
> The cell size used for grid computation is set globally in **Project Settings** → `fusion/interest_management/area_of_interest_cell_size`. All FusionInterestArea nodes and replicators with `INTEREST_AREA` mode share this cell size.
