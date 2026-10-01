## First-person player with replicated movement, jumping and mouse look.
class_name Player
extends CharacterBody3D

const MOUSE_SENSITIVITY: float = 0.001
const MAX_PITCH: float = 1.5
const PUSH_STRENGTH: float = 10.0

# Input payload: move x, move y, yaw, pitch (floats) followed by a flags byte
const INPUT_SIZE: int = 17
const FLAG_JUMP: int = 1
const FLAG_PUSH: int = 2

@export var move_speed: float = 5.0
@export var jump_speed: float = 5.5
@export var gravity: float = 15.0

@onready var replicator: FusionServerReplicator = %FusionServerReplicator
@onready var camera: Camera3D = %Camera3D
@onready var reach: RayCast3D = %Reach
@onready var mesh: MeshInstance3D = %MeshInstance3D
@onready var label_owner: Label3D = %LabelOwner

# Kept apart from the replicated rotation, which lags behind and would undo mouse look
var _look_yaw: float = 0.0


# BUILT-IN METHODS

func _ready() -> void:
    # Connect signals
    replicator.on_process_input.connect(_on_process_input)

    # Input authority is set before spawning, so it is already known here
    _on_authority_changed(replicator.has_input_authority())

    _look_yaw = rotation.y

    # Avoid a visible streak from the origin to the spawn position
    reset_physics_interpolation()


func _physics_process(delta: float) -> void:
    if replicator.has_input_authority():
        # Replication may have just overwritten the rotation with an older state
        rotation.y = _look_yaw
        replicator.queue_input(delta, _create_input())
    replicator.process_input_queue(delta)


func _unhandled_input(event: InputEvent) -> void:
    if not replicator.has_input_authority():
        return

    if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        if event is InputEventMouseMotion:
            var look_dir: Vector2 = (event as InputEventMouseMotion).relative * MOUSE_SENSITIVITY
            _look_yaw -= look_dir.x
            rotation.y = _look_yaw
            camera.rotation.x = clamp(camera.rotation.x - look_dir.y, -MAX_PITCH, MAX_PITCH)
    elif event is InputEventMouseButton:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


# SIGNAL HANDLERS

func _on_authority_changed(has_input_authority: bool) -> void:
    label_owner.text = str(replicator.get_input_authority())
    # The local camera sits inside the capsule, so hide our own body
    mesh.visible = not has_input_authority
    camera.current = has_input_authority
    if has_input_authority:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_process_input(
    _tick: int, delta_time: float, payload: PackedByteArray, _is_new: bool
) -> void:
    var input_dir: Vector2 = Vector2(payload.decode_float(0), payload.decode_float(4))
    var flags: int = payload.decode_u8(16)

    # Look comes with the input so the host aims exactly where the client did
    rotation.y = payload.decode_float(8)
    camera.rotation.x = payload.decode_float(12)

    # Handle gravity
    if not is_on_floor():
        velocity.y -= gravity * delta_time

    # Handle jump
    if flags & FLAG_JUMP and is_on_floor():
        velocity.y = jump_speed

    # Push the ball being looked at, balls are owned by the host so only it can push
    if flags & FLAG_PUSH and Fusion.is_master_client():
        reach.force_raycast_update()
        var ball: Ball = _get_detected_ball()
        if ball:
            ball.push(-camera.global_transform.basis.z * PUSH_STRENGTH)

    # Calculate movement direction
    var direction: Vector3 = global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)
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


# PRIVATE METHODS

func _create_input() -> PackedByteArray:
    var input_dir: Vector2 = Input.get_vector(
        "move_left", "move_right", "move_forward", "move_backward"
    )
    var flags: int = 0
    if Input.is_action_just_pressed("move_jump"):
        flags |= FLAG_JUMP
    if Input.is_action_just_pressed("primary") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        flags |= FLAG_PUSH

    var payload: PackedByteArray = PackedByteArray()
    payload.resize(INPUT_SIZE)
    payload.encode_float(0, input_dir.x)
    payload.encode_float(4, input_dir.y)
    payload.encode_float(8, rotation.y)
    payload.encode_float(12, camera.rotation.x)
    payload.encode_u8(16, flags)
    return payload


func _get_detected_ball() -> Ball:
    if not reach.is_colliding():
        return null

    return reach.get_collider() as Ball
