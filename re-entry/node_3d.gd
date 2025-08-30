extends OmniLight3D

enum LightState {
	NORMAL,
	ALARM,
	BOOTING,
	LIGHTS_OUT
}
@export var debug_state: LightState = LightState.NORMAL:
	set(value):
		debug_state = value
		set_state(value)

# Per-state configs
@export var normal_intensity: float = 1.0
@export var normal_color: Color = Color(1, 1, 1)   # white

@export var alarm_intensity: float = 1.0
@export var alarm_color: Color = Color(1, 0, 0)   # red

@export var boot_duration: float = 3.0
@export var boot_color: Color = Color(0.6, 0.8, 1.0) # pale blue

@export var lights_out_intensity: float = 0.0
@export var lights_out_color: Color = Color(0,0,0) # pale blue

var current_state: LightState = LightState.NORMAL
var time_passed := 0.0

func _process(delta):
	time_passed += delta
	
	match current_state:
			
		LightState.NORMAL:
			# Subtle sine flicker
			light_color = normal_color
			light_energy = 1
		
		LightState.ALARM:
			# Strong pulse
			light_color = alarm_color
			var pulse = (sin(time_passed * 4.0 * TAU) + 1.0) * 0.5
			light_energy = pulse * alarm_intensity
		
		LightState.LIGHTS_OUT:
			light_color = lights_out_color
			light_energy = 0
		
		LightState.BOOTING:
			# Ramp up + flicker
			light_color = boot_color
			var t = clamp(time_passed / boot_duration, 0.0, 1.0)
			var flicker = randf_range(0.8, 1.0) if randf() < 0.2 else 1.0
			light_energy = normal_intensity * t * flicker
			
			if t >= 1.0:
				set_state(LightState.NORMAL)


func set_state(new_state: LightState):
	current_state = new_state
	time_passed = 0.0
