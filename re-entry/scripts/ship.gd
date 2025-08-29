extends Node

@export var start_velocity: Vector3 = Vector3(0, -1000, 0) # meters
@export var start_rotation: Vector3 = Vector3(0, 0, 0) # degrees
@export var start_position: Vector3 = Vector3(0, 6571000, 0) # meters

@export var start_dry_mass: float = 1000 # kg
@export var start_fuel_mass: float = 1000 # kg

@export var drag_area: float = 4 # m^2
@export var drag_coef: float = 0.42

# thrust at sea level and outside atmosphere
@export var thrust_curve: Vector2 = Vector2(20000, 30000) # newtons
@export var thrust_fuel_drain: float = 10 # kg/s

@export var gravity: float = 9.81 # meters/s^2

@export var planet_radius: float = 6371000 # meters

# the radius of atmosphere added on top of planet
@export var atmosphere_height: float = 100000 # meters
# density at sea level, and at max atmosphere height
# assume some simple log falloff
@export var atmosphere_density_curve: Vector2 = Vector2(1.29, 0) # kg/m^3

@onready var nav_ball: Node3D = $NavBall

@onready var debug_label: Label = $DebugLabel

var velocity: Vector3
var orientation: Quaternion
var position: Vector3

var dry_mass: float
var fuel_mass: float

var is_thrusting: bool

func get_sea_level() -> float:
	return planet_radius

# i love spheres
func get_elevation() -> float:
	return position.length() - self.get_sea_level() 

func get_atmosphere_fraction() -> float:
	return clamp(
		1.0 - inverse_lerp(
			0,
			atmosphere_height,
			self.get_elevation()
		),
		0,
		1
	)

func get_atmosphere_density() -> float:
	return lerp(
		atmosphere_density_curve.y,
		atmosphere_density_curve.x,
		pow(self.get_atmosphere_fraction(), 10)
	)

func get_thrust() -> float:
	return lerp(thrust_curve.y, thrust_curve.x, self.get_atmosphere_fraction())

func get_mass() -> float:
	return dry_mass + fuel_mass

func get_drag() -> float:
	# https://en.wikipedia.org/wiki/Drag_coefficient
	# c = 2 * F / ( p * u^2 * A )
	# -> F = 0.5 * c * p * u^2 * A
	return (0.5 * drag_coef * self.get_atmosphere_density()
		* velocity.length_squared() * drag_area)

func _ready():
	velocity = start_velocity
	orientation = Quaternion.from_euler(start_rotation)
	position = start_position
	dry_mass = start_dry_mass
	fuel_mass = start_fuel_mass
	is_thrusting = false

func _process(delta: float) -> void:
	# TODO these are temporary inputs
	if Input.is_action_pressed("ui_select"):
		is_thrusting = true
	else:
		is_thrusting = false

func _physics_process(delta: float) -> void:
	var to_center = -position.normalized()
	velocity += to_center * gravity * delta
	
	var drag_accel = self.get_drag() / self.get_mass()
	velocity -= velocity.normalized() * drag_accel * delta
	
	if is_thrusting and fuel_mass > 0:
		var wanted_fuel = thrust_fuel_drain * delta
		var used_fuel = min(fuel_mass, wanted_fuel)
		var used_ratio = used_fuel / wanted_fuel
		fuel_mass -= used_fuel

		var up = (orientation * Vector3(0, 1, 0)).normalized()
		velocity += delta * used_ratio * up * (self.get_thrust() / self.get_mass())
	
	position += velocity * delta
	
	debug_label.text = "mass: %f kg\n" % self.get_mass()
	debug_label.text += "thrusting: %s, force: %f N\n" % [is_thrusting, self.get_thrust()]
	debug_label.text += "pos: %v m\n" % position
	debug_label.text += "vel: %v m\n" % velocity
	debug_label.text += "elevation: %f m\n" % self.get_elevation()
	debug_label.text += "atm: %f kg/m^3\n" % self.get_atmosphere_density()
	debug_label.text += "drag: %f N\n" % self.get_drag()
