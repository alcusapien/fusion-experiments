## Rigid body ball that any player can push, taking authority over it when they do.
class_name Ball
extends RigidBody3D

const UPDATE_INTERVAL_FULL: int = 1
const UPDATE_INTERVAL_YIELD: int = 16

@onready var replicator: FusionSharedReplicator = %FusionSharedReplicator
@onready var label_owner: Label3D = %LabelOwner
@onready var detection_area: Area3D = %DetectionArea


# BUILT-IN METHODS

func _ready() -> void:
    # Connect signals
    replicator.authority_changed.connect(_on_authority_changed)
    _on_authority_changed(replicator.has_authority())


func _physics_process(_delta: float) -> void:
    if not replicator.has_authority():
        return

    # Send full updates only while the authority is the closest player, otherwise yield
    var closest_player_id: int = _get_closest_player_id()
    if closest_player_id == -1:
        return

    var is_closest: bool = closest_player_id == Fusion.get_local_player_id()
    var new_update_interval: int = UPDATE_INTERVAL_FULL if is_closest else UPDATE_INTERVAL_YIELD
    if new_update_interval != replicator.update_interval:
        replicator.update_interval = new_update_interval


# PUBLIC METHODS

func push(impulse: Vector3) -> void:
    if not replicator.has_authority():
        replicator.want_authority(true, UPDATE_INTERVAL_FULL)

    apply_central_impulse(impulse)


# SIGNAL HANDLERS

func _on_authority_changed(_has_authority: bool) -> void:
    replicator.update_interval = UPDATE_INTERVAL_FULL
    label_owner.text = str(replicator.get_owner_id())


# PRIVATE METHODS

func _get_closest_player_id() -> int:
    var closest_player_id: int = replicator.get_owner_id()
    var closest_distance: float = INF

    for body: Node3D in detection_area.get_overlapping_bodies():
        var player: Player = body as Player
        if not player:
            continue

        var distance: float = global_position.distance_to(player.global_position)
        if distance < closest_distance:
            closest_distance = distance
            closest_player_id = player.replicator.get_owner_id()

    return closest_player_id
