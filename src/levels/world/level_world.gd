class_name LevelWorld
extends Node3D

const MainScenePath: String = "res://src/main.tscn"
const PlayerScene: PackedScene = preload("res://src/scenes/player/player.tscn")

# Set by the menu before this level is loaded
static var room_code: String = ""
static var is_creating_room: bool = false
# Shown by the menu when the level bounces back after a failure
static var last_error: String = ""

@onready var player_spawner: FusionSpawner = %SpawnerPlayers


# BUILT-IN METHODS

func _ready() -> void:
    last_error = ""

    # Register spawnable scenes
    player_spawner.add_spawnable_scene(PlayerScene)

    # Connect signals
    Fusion.room_joined.connect(_on_room_joined)
    Fusion.connection_failed.connect(_on_connection_failed)

    # Join only after the level is loaded so the pre-placed objects exist to be matched
    if is_creating_room:
        Fusion.create_room(room_code)
    else:
        Fusion.join_room(room_code)


# SIGNAL HANDLERS

func _on_room_joined() -> void:
    # Make sure the pre-placed scene objects are registered
    if Fusion.is_master_client():
        Fusion.register_current_scene()
        for ball: Ball in get_tree().get_nodes_in_group("balls"):
            ball.replicator.want_authority(true)

    player_spawner.spawn(PlayerScene, _pre_spawn_player)


func _on_connection_failed(error: String) -> void:
    last_error = error
    get_tree().change_scene_to_file(MainScenePath)


# PRIVATE METHODS

func _pre_spawn_player(_replicator: Variant, player: Player) -> void:
    var player_id: int = Fusion.get_local_player_id()
    player.position = Vector3.ZERO if player_id == 1 else Vector3(0, 0, -10)
    player.rotation = Vector3.ZERO if player_id == 1 else Vector3.UP * deg_to_rad(180)
