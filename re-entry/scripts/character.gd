extends Node3D

@export var sensitivity: float = 2.0

@onready var camera: Camera3D = $Camera3D

var mouse_input = Vector2()


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	var pitch = camera.rotation_degrees.x
	var new_pitch = pitch - mouse_input.y * sensitivity * 0.022
	new_pitch = clampf(new_pitch, -89, 89)
	var pitch_delta = new_pitch - pitch
	
	rotate_y(deg_to_rad(mouse_input.x * sensitivity * 0.022))
	camera.rotate_x(deg_to_rad(pitch_delta))
	
	mouse_input.x = 0
	mouse_input.y = 0

func _input(event):
	if Engine.is_editor_hint():
		return
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_input.x = -event.relative.x
		mouse_input.y = event.relative.y
