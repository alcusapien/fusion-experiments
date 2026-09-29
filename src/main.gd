## Main menu with a room code input and buttons to join or create a room.
extends Control

const LevelScene: PackedScene = preload("res://src/levels/world/level_world.tscn")

@onready var room_code_input: LineEdit = %RoomCodeInput
@onready var join_button: Button = %JoinButton
@onready var create_button: Button = %CreateButton
@onready var status_label: Label = %StatusLabel


# BUILT-IN METHODS

func _ready() -> void:
    # Buttons stay disabled until Photon is connected
    _set_buttons_disabled(true)

    # Connect signals
    Fusion.connected_to_photon.connect(_on_connected_to_photon)
    Fusion.connection_failed.connect(_on_connection_failed)
    Fusion.room_joined.connect(_on_room_joined)

    # Connect to Photon
    status_label.text = "Connecting..."
    Fusion.connect_to_photon.call_deferred()


# SIGNAL HANDLERS

func _on_connected_to_photon() -> void:
    status_label.text = "Connected"
    _set_buttons_disabled(false)


func _on_connection_failed(error: String) -> void:
    status_label.text = error
    _set_buttons_disabled(not Fusion.is_connected_to_photon())


func _on_room_joined() -> void:
    get_tree().change_scene_to_packed(LevelScene)


func _on_join_button_pressed() -> void:
    var room: String = _get_room_code()
    if room.is_empty():
        return

    status_label.text = "Joining room..."
    _set_buttons_disabled(true)
    Fusion.join_room(room)


func _on_create_button_pressed() -> void:
    var room: String = _get_room_code()
    if room.is_empty():
        return

    status_label.text = "Creating room..."
    _set_buttons_disabled(true)
    Fusion.create_room(room)


# PRIVATE METHODS

func _get_room_code() -> String:
    var room: String = room_code_input.text.strip_edges()
    if room.is_empty():
        status_label.text = "Enter a room code"
    return room


func _set_buttons_disabled(disabled: bool) -> void:
    join_button.disabled = disabled
    create_button.disabled = disabled
