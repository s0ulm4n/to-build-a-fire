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

var fuel: int

var _current_size: FireSize

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
	_change_fire_size(_current_size)
	fire_sfx.play()
	

func _process(_delta: float) -> void:
	if fuel > 0:
		fire_sprite.visible = true
		if burn_timer.is_stopped():
			burn_timer.start()
			fire_sfx.play()
			embers_smoke_timer.stop()
	else:
		fire_sprite.visible = false


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		enter_warm_zone.emit(self)
		

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		exit_warm_zone.emit(self)
		

func _on_burn_timer_timeout() -> void:
	fuel -= 1
	
	if fuel > 0:
		if fuel > FIRE_SIZE_FUEL_THRESHOLDS[FireSize.LARGE]:
			_change_fire_size(FireSize.LARGE)
		elif fuel > FIRE_SIZE_FUEL_THRESHOLDS[FireSize.MEDIUM]:
			_change_fire_size(FireSize.MEDIUM)
		elif fuel > FIRE_SIZE_FUEL_THRESHOLDS[FireSize.SMALL]:
			_change_fire_size(FireSize.SMALL)
		else:
			_change_fire_size(FireSize.TINY)
	else:
		_change_fire_size(FireSize.EXTINGUISHED)
		burn_timer.stop()
		fire_sfx.stop()
		embers_smoke_timer.start()


func _on_embers_smoke_timer_timeout() -> void:
	smoke_particles.amount_ratio -= 0.03
	clamp(smoke_particles.amount_ratio, 0, 1)


func _change_fire_size(new_size: FireSize) -> void:
	if _current_size == new_size:
		pass
	
	match new_size:
		FireSize.LARGE:
			_update_fire_properties("burn_1", -13, 0.2, 1.0)
		FireSize.MEDIUM:
			_update_fire_properties("burn_2", -10, 0.3, 0.5)
		FireSize.SMALL:
			_update_fire_properties("burn_4", -8, 0.5, 0.0)
		FireSize.TINY:
			_update_fire_properties("burn_5", -2, 0.6, -1.0)
		FireSize.EXTINGUISHED:
			fire_sprite.stop()
			smoke_particles.amount_ratio = 1.0
			burn_timer.stop()
			fire_sfx.stop()
			embers_smoke_timer.start()


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
