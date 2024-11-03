class_name Fire
extends Area2D
## Campfire object
##
## Keeps track of its fuel amount, emits signals on player
## entering or leaving the warming effect area.

signal enter_warm_zone(fire: Fire)
signal exit_warm_zone(fire: Fire)

enum FireSize {
	LARGE,
	MEDIUM,
	SMALL,
	TINY,
	EXTINGUISHED,
}

# If the amount of fuel in a fire is higher than 
# FIRE_SIZE_FUEL_THRESHOLDS[FireSize.SMALL] but lower than
# FIRE_SIZE_FUEL_THRESHOLDS[FireSize.MEDIUM],
# the fire size is FireSize.SMALL
const FIRE_SIZE_FUEL_THRESHOLDS := {
	FireSize.LARGE: 15,
	FireSize.MEDIUM: 8,
	FireSize.SMALL: 3,
	FireSize.TINY: 0,
}
const STARTING_FUEL: int = 10
const FUEL_FROM_LOG: int = 5

var fuel: int: set = _set_fuel

var _current_size: FireSize: set = _set_current_size

@onready var fire_sprite: AnimatedSprite2D = $FireSprite
@onready var fire_sfx: AudioStreamPlayer2D = $FireSFX
@onready var smoke_particles: GPUParticles2D = $SmokeParticles
## Timer that reduces the amount of fuel while the fire is burning
@onready var burn_timer: Timer = $BurnTimer
## Once the fire goes out, this timer reduces the amount of emitted smoke
## to simulate the campfire embers "cooling down"
@onready var embers_smoke_timer: Timer = $EmbersSmokeTimer

func _ready() -> void:
	fuel = STARTING_FUEL
	_current_size = FireSize.MEDIUM
	fire_sfx.play()

# Getters and setters

## Setter for the _fuel property.
## Handles starting and stopping appropriate timers.
func _set_fuel(value: int) -> void:
	fuel = max(value, 0)
	
	if fuel > 0 && burn_timer.is_stopped():
		burn_timer.start()
		fire_sfx.play()
		embers_smoke_timer.stop()
	elif fuel == 0 && !burn_timer.is_stopped():
		burn_timer.stop()
		embers_smoke_timer.start()


## Setter for the _current_size property.
## Handles visual and audio properties of the fire
func _set_current_size(new_size: FireSize) -> void:
	if _current_size == new_size:
		pass
		
	_current_size = new_size
	match _current_size:
		FireSize.LARGE:
			_update_fire_properties("burn_1", -13, 0.2, 1.0)
		FireSize.MEDIUM:
			_update_fire_properties("burn_2", -10, 0.3, 0.5)
		FireSize.SMALL:
			_update_fire_properties("burn_4", -8, 0.5, 0.0)
		FireSize.TINY:
			_update_fire_properties("burn_5", -2, 0.6, -1.0)
		FireSize.EXTINGUISHED:
			fire_sprite.visible = false
			fire_sfx.stop()
			smoke_particles.amount_ratio = 1.0

# End Getters and setters

# Timers

func _on_burn_timer_timeout() -> void:
	fuel -= 1
	
	if fuel > 0:
		if fuel > FIRE_SIZE_FUEL_THRESHOLDS[FireSize.LARGE]:
			_current_size = FireSize.LARGE
		elif fuel > FIRE_SIZE_FUEL_THRESHOLDS[FireSize.MEDIUM]:
			_current_size = FireSize.MEDIUM
		elif fuel > FIRE_SIZE_FUEL_THRESHOLDS[FireSize.SMALL]:
			_current_size = FireSize.SMALL
		else:
			_current_size = FireSize.TINY
	else:
		_current_size = FireSize.EXTINGUISHED
		burn_timer.stop()
		fire_sfx.stop()
		embers_smoke_timer.start()


func _on_embers_smoke_timer_timeout() -> void:
	smoke_particles.amount_ratio -= 0.03
	clamp(smoke_particles.amount_ratio, 0, 1)

# End Timers

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		enter_warm_zone.emit(self)
		

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		exit_warm_zone.emit(self)


## Util function to bundle updates fire properties.
## This always sets `fire_sprite.visible` to true
func _update_fire_properties(
		animation_name: String, 
		sprite_y_offset: int,
		smoke_amount_ratio: float,
		sfx_volume_db: float,
		) -> void:
	fire_sprite.visible = true
	fire_sprite.play(animation_name)	
	# This offset SHOULD have been baked into the sprite,
	# but what are you gonna do?
	fire_sprite.position.y = sprite_y_offset
	smoke_particles.amount_ratio = smoke_amount_ratio
	fire_sfx.volume_db = sfx_volume_db
