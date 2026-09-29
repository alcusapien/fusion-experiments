class_name Ball
extends RigidBody3D

@onready var replicator: FusionSharedReplicator = %FusionSharedReplicator
@onready var label_owner: Label3D = %LabelOwner


# BUILT-IN METHODS

func _ready() -> void:
    # Connect signals
    replicator.authority_changed.connect(_on_authority_changed)
    _on_authority_changed(replicator.has_authority())


# PUBLIC METHODS

func push(impulse: Vector3) -> void:
    if not replicator.has_authority():
        replicator.want_authority(true)

    apply_central_impulse(impulse)


# SIGNAL HANDLERS

func _on_authority_changed(_has_authority: bool) -> void:
    label_owner.text = str(replicator.get_owner_id())
