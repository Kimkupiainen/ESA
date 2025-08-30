extends Node3D

@export var lerp_speed: float = 0.1

var ship_position: Vector3 = Vector3.UP
var ship_rotation: Quaternion = Quaternion.IDENTITY

func _ready():
	var ship = get_node('/root/Ship')
	ship.position_changed.connect(_on_ship_position_changed)
	ship.rotation_changed.connect(_on_ship_rotation_changed)

func _on_ship_position_changed(new_value):
	ship_position = new_value

func _on_ship_rotation_changed(new_value):
	ship_rotation = new_value

func _process(delta: float) -> void:
	var gravity_axis = ship_position.normalized()
	var navball_up = ship_rotation.inverse() * gravity_axis
	var ship_fwd = ship_rotation * Vector3.FORWARD
	var navball_fwd = navball_up.cross(Vector3.FORWARD)
	if navball_fwd.length_squared() < 0.1:
		# navball_up and Vector3.UP happen to be parallel
		navball_fwd = navball_up.cross(Vector3.UP)
	if navball_fwd.dot(ship_fwd) > 0:
		navball_fwd = -navball_fwd
	#print("nav up: %v" % navball_up)
	#print("nav fwd: %v" % navball_fwd)
	look_at(ship_position + navball_fwd * 1000, navball_up)
	
