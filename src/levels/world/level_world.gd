class_name LevelWorld
extends Node3D

const MainScenePath: String = "res://src/main.tscn"
const PlayerScene: PackedScene = preload("res://src/scenes/player/player.tscn")
# The room creator is the first player in the room and acts as the host
const HOST_PLAYER_ID: int = 1

# Set by the menu before this level is loaded
static var room_code: String = ""
static var is_creating_room: bool = false
# Shown by the menu when the level bounces back after a failure
static var last_error: String = ""

@onready var player_spawner: FusionSpawner = %SpawnerPlayers

var _players_by_id: Dictionary[int, Player] = {}


# BUILT-IN METHODS

func _ready() -> void:
    last_error = ""

    # Register spawnable scenes
    player_spawner.add_spawnable_scene(PlayerScene)

    # Connect signals
    Fusion.room_joined.connect(_on_room_joined)
    Fusion.connection_failed.connect(_on_connection_failed)
    Fusion.player_left.connect(_on_player_left)
    Fusion.room_left.connect(_on_room_left)
    Fusion.register_broadcast_receiver(self)

    # Join only after the level is loaded so the pre-placed objects exist to be matched
    if is_creating_room:
        Fusion.create_room(room_code)
    else:
        Fusion.join_room(room_code)


func _exit_tree() -> void:
    if Fusion:
        Fusion.unregister_broadcast_receiver(self)


# SIGNAL HANDLERS

func _on_room_joined() -> void:
    if Fusion.is_master_client():
        # Make sure the pre-placed scene objects are registered
        Fusion.register_current_scene()
        _spawn_player(Fusion.get_local_player_id())
    else:
        Fusion.rpc(request_spawn)


func _on_player_left(player_id: int, is_inactive: bool) -> void:
    # The session lives on the host, so it ends when the host leaves
    if player_id == HOST_PLAYER_ID and not Fusion.is_master_client():
        _leave_with_error("Host left the room")
        return

    # Keep the character of an inactive player, they may rejoin within the TTL
    if not Fusion.is_master_client() or is_inactive:
        return

    var player: Player = _players_by_id.get(player_id)
    if player:
        player_spawner.despawn(player)
        _players_by_id.erase(player_id)


func _on_room_left() -> void:
    _leave_with_error("Disconnected from the room")


func _on_connection_failed(error: String) -> void:
    _leave_with_error(error)


# RPCS

@rpc("any_peer", "call_local")
func request_spawn() -> void:
    if not Fusion.is_master_client():
        return

    _spawn_player(Fusion.get_rpc_sender())


# PRIVATE METHODS

func _spawn_player(player_id: int) -> void:
    if _players_by_id.has(player_id):
        return

    var pre_spawn: Callable = func(replicator: FusionServerReplicator, player: Player) -> void:
        replicator.set_input_authority(player_id)
        player.position = Vector3.ZERO if player_id == HOST_PLAYER_ID else Vector3(0, 0, -6)
        player.rotation = Vector3.ZERO if player_id == HOST_PLAYER_ID else Vector3.UP * deg_to_rad(180)

    _players_by_id[player_id] = player_spawner.spawn(PlayerScene, pre_spawn)


func _leave_with_error(error: String) -> void:
    if last_error.is_empty():
        last_error = error
    get_tree().change_scene_to_file(MainScenePath)
