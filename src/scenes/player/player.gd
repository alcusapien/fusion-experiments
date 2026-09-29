## First-person player with replicated movement, jumping and mouse look.
class_name Player
extends CharacterBody3D

const MOUSE_SENSITIVITY: float = 0.001
const MAX_PITCH: float = 1.5

@export var move_speed: float = 5.0
@export var jump_speed: float = 5.5
@export var gravity: float = 15.0

@onready var replicator: FusionSharedReplicator = %FusionSharedReplicator
@onready var camera: Camera3D = %Camera3D
@onready var mesh: MeshInstance3D = %MeshInstance3D
@onready var label_owner: Label3D = %LabelOwner


# BUILT-IN METHODS

func _ready() -> void:
    # Connect signals
    replicator.authority_changed.connect(_on_authority_changed)
    _on_authority_changed(replicator.has_authority())

    # Avoid a visible streak from the origin to the spawn position
    reset_physics_interpolation()


func _physics_process(delta: float) -> void:
    # Prevent peers from controlling other players
    if not replicator.has_authority():
        return

    # Handle gravity
    if not is_on_floor():
        velocity.y -= gravity * delta

    # Handle jump
    if Input.is_action_just_pressed("move_jump") and is_on_floor():
        velocity.y = jump_speed

    # Calculate movement direction
    var input_dir: Vector2 = Input.get_vector(
        "move_left", "move_right", "move_forward", "move_backward"
    )
    var direction: Vector3 = camera.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)
    direction.y = 0
    direction = direction.normalized()

    # Apply horizontal velocity
    if direction:
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
    else:
        velocity.x = move_toward(velocity.x, 0, move_speed)
        velocity.z = move_toward(velocity.z, 0, move_speed)

    move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
    if not replicator.has_authority():
        return

    if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        if event is InputEventMouseMotion:
            var look_dir: Vector2 = (event as InputEventMouseMotion).relative * MOUSE_SENSITIVITY
            rotation.y -= look_dir.x
            camera.rotation.x = clamp(camera.rotation.x - look_dir.y, -MAX_PITCH, MAX_PITCH)
    elif event is InputEventMouseButton:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


# SIGNAL HANDLERS

func _on_authority_changed(has_authority: bool) -> void:
    label_owner.text = str(replicator.get_owner_id())
    # The local camera sits inside the capsule, so hide our own body
    mesh.visible = not has_authority
    camera.current = has_authority
    if has_authority:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
