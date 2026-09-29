## Main menu with a room code input and buttons to join or create a room.
extends Control

const LevelScene: PackedScene = preload("res://src/levels/world/level_world.tscn")

@onready var room_code_input: LineEdit = %RoomCodeInput
@onready var join_button: Button = %JoinButton
@onready var create_button: Button = %CreateButton
@onready var status_label: Label = %StatusLabel


# BUILT-IN METHODS

func _ready() -> void:
    # Connect signals
    Fusion.connected_to_photon.connect(_on_connected_to_photon)
    Fusion.connection_failed.connect(_on_connection_failed)

    # The level bounces back here when joining fails, already connected
    if Fusion.is_connected_to_photon():
        _on_connected_to_photon()
        if not LevelWorld.last_error.is_empty():
            status_label.text = LevelWorld.last_error
        return

    # Buttons stay disabled until Photon is connected
    _set_buttons_disabled(true)
    status_label.text = "Connecting..."
    Fusion.connect_to_photon.call_deferred()


# SIGNAL HANDLERS

func _on_connected_to_photon() -> void:
    status_label.text = "Connected"
    _set_buttons_disabled(false)


func _on_connection_failed(error: String) -> void:
    status_label.text = error
    _set_buttons_disabled(not Fusion.is_connected_to_photon())


func _on_join_button_pressed() -> void:
    _load_level(false)


func _on_create_button_pressed() -> void:
    _load_level(true)


# PRIVATE METHODS

func _load_level(is_creating: bool) -> void:
    var room: String = room_code_input.text.strip_edges()
    if room.is_empty():
        status_label.text = "Enter a room code"
        return

    # The level joins the room itself so it is loaded before the room state arrives
    LevelWorld.room_code = room
    LevelWorld.is_creating_room = is_creating
    get_tree().change_scene_to_packed(LevelScene)


func _set_buttons_disabled(disabled: bool) -> void:
    join_button.disabled = disabled
    create_button.disabled = disabled
