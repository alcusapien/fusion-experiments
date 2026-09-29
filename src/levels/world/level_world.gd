extends Node3D

const PlayerScene: PackedScene = preload("res://src/scenes/player/player.tscn")

@onready var player_spawner: FusionSpawner = %SpawnerPlayers


# BUILT-IN METHODS

func _ready() -> void:
    # Register spawnable scenes
    player_spawner.add_spawnable_scene(PlayerScene)

    # Make sure the pre-placed scene objects are registered
    if Fusion.is_master_client():
        Fusion.register_current_scene()

    # The room is already joined by the time the menu loads this level
    player_spawner.spawn(PlayerScene, _pre_spawn_player)


# PRIVATE METHODS

func _pre_spawn_player(_replicator: Variant, player: Player) -> void:
    var player_id: int = Fusion.get_local_player_id()
    player.position = Vector3.ZERO if player_id == 1 else Vector3(0, 0, -10)
    player.rotation = Vector3.ZERO if player_id == 1 else Vector3.UP * deg_to_rad(180)
