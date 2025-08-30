extends Node

const PHYS_UPDATE_FREQ: int = 10

@export var start_velocity: Vector3 = Vector3(0, -1000, 0) # meters
@export var start_rotation: Vector3 = Vector3(0, 0, 0) # radians!
@export var start_position: Vector3 = Vector3(0, 6401000, 0) # meters

@export var start_dry_mass: float = 800 # kg
@export var start_fuel_mass: float = 1000 # kg
@export var start_heatshield_mass: float = 200 # kg

@export var drag_area: float = 4 # m^2
@export var drag_coef: float = 0.42
# magic numbers for drag heating
@export var drag_heating: float = 0.1
@export var drag_ablation: float = 0.0005 # kg/J
@export var ablation_limit: float = 50000 # J
# heat loss from airflow, simply ignore at high speeds
@export var heat_loss: float = 30 # J/m/s^2
@export var heat_loss_speed_limit: float = 300 # m/s

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
var heatshield_mass: float
var heat_energy: float

var is_thrusting: bool

var phys_delta: float = 0

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
	return dry_mass + fuel_mass + heatshield_mass

func get_drag() -> float:
	# https://en.wikipedia.org/wiki/Drag_coefficient
	# c = 2 * F / ( p * u^2 * A )
	# -> F = 0.5 * c * p * u^2 * A
	return (0.5 * drag_coef * self.get_atmosphere_density()
		* velocity.length_squared() * drag_area)

func get_up_vec() -> Vector3:
	return (orientation * Vector3(0, 1, 0)).normalized()

func _ready():
	velocity = start_velocity
	orientation = Quaternion.from_euler(start_rotation)
	position = start_position
	dry_mass = start_dry_mass
	fuel_mass = start_fuel_mass
	heatshield_mass = start_heatshield_mass
	is_thrusting = false

func _process(delta: float) -> void:
	# TODO these are temporary inputs
	if Input.is_action_pressed("ui_select"):
		is_thrusting = true
	else:
		is_thrusting = false

func _physics_process(delta: float) -> void:
	# avoid FP32 precision issues :(
	phys_delta += delta
	if phys_delta < 1.0 / PHYS_UPDATE_FREQ:
		return
	
	# gravity
	var to_center = -position.normalized()
	velocity += to_center * gravity * phys_delta
	
	# atm. drag
	var drag_accel = self.get_drag() / self.get_mass()
	velocity -= velocity.normalized() * drag_accel * phys_delta
	
	# atm. drag / compression heating
	heat_energy += self.get_drag() * drag_heating * phys_delta
	
	# heat loss from airflow
	if velocity.length() < heat_loss_speed_limit:
		var loss = velocity.length() * heat_loss * phys_delta
		heat_energy = max(0, heat_energy - loss)
	
	# heat loss from ablation
	if heatshield_mass > 0 and heat_energy > ablation_limit:
		# are we spicy side down?
		var heatshield_effectiveness = velocity.normalized().dot(-self.get_up_vec())
		heatshield_effectiveness = clamp(heatshield_effectiveness, 0, 1)
		
		var wanted_ablation = heatshield_effectiveness * drag_ablation * (heat_energy - ablation_limit)
		var actual_ablation = min(heatshield_mass, wanted_ablation)
		heatshield_mass -= actual_ablation
		heat_energy -= actual_ablation / drag_ablation
	
	# main engine thrust
	if is_thrusting and fuel_mass > 0:
		var wanted_fuel = thrust_fuel_drain * phys_delta
		var used_fuel = min(fuel_mass, wanted_fuel)
		var used_ratio = used_fuel / wanted_fuel
		fuel_mass -= used_fuel
		velocity += phys_delta * used_ratio * self.get_up_vec() * (self.get_thrust() / self.get_mass())
	
	position += velocity * phys_delta
	phys_delta = 0
	
	debug_label.text = "mass: %f kg\n" % self.get_mass()
	debug_label.text += "  fuel: %f kg\n" % fuel_mass
	debug_label.text += "  heatshield: %f kg\n" % heatshield_mass
	debug_label.text += "heat: %f J\n" % heat_energy
	debug_label.text += "thrusting: %s, force: %f N\n" % [is_thrusting, self.get_thrust()]
	debug_label.text += "pos: %v m\n" % position
	debug_label.text += "vel: %v m\n" % velocity
	debug_label.text += "elevation: %f m\n" % self.get_elevation()
	debug_label.text += "atm: %f kg/m^3\n" % self.get_atmosphere_density()
	debug_label.text += "drag: %f N\n" % self.get_drag()
