extends Area2D
class_name Fire

enum FireSize {
	Large,
	Medium,
	Small,
	Tiny,
	Extinguished,
}

const STARTING_FUEL: int = 10
const FUEL_FROM_LOG: int = 5

# If the amount of fuel in a fire is higher than 
# FIRE_SIZE_FUEL_THRESHOLDS[FireSize.Small] but lower than
# FIRE_SIZE_FUEL_THRESHOLDS[FireSize.Medium],
# the fire size is FireSize.Small
const FIRE_SIZE_FUEL_THRESHOLDS = {
	FireSize.Large: 15,
	FireSize.Medium: 8,
	FireSize.Small: 3,
	FireSize.Tiny: 0,
}

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _smoke: GPUParticles2D = $GPUParticles2D
@onready var _burn_timer: Timer = $BurnTimer
@onready var _embers_smoke_timer: Timer = $EmbersSmokeTimer
@onready var _fire_sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D

var fuel: int
var current_size: FireSize

signal enter_warm_zone(fire: Fire)
signal exit_warm_zone(fire: Fire)

func _ready() -> void:
	fuel = STARTING_FUEL
	current_size = FireSize.Medium
	change_fire_size(current_size)
	_fire_sfx.play()

func _process(_delta: float) -> void:
	if (fuel > 0):
		_sprite.visible = true
		if (_burn_timer.is_stopped()):
			_burn_timer.start()
			_fire_sfx.play()
			_embers_smoke_timer.stop()
	else:
		_sprite.visible = false

func _on_body_entered(body: Node2D) -> void:
	if (body is Player):
		enter_warm_zone.emit(self)

func _on_body_exited(body: Node2D) -> void:
	if (body is Player):
		exit_warm_zone.emit(self)

func _on_burn_timer_timeout() -> void:
	fuel -= 1
	
	if (fuel > 0):
		if (fuel > FIRE_SIZE_FUEL_THRESHOLDS[FireSize.Large]):
			change_fire_size(FireSize.Large)
		elif (fuel > FIRE_SIZE_FUEL_THRESHOLDS[FireSize.Medium]):
			change_fire_size(FireSize.Medium)
		elif (fuel > FIRE_SIZE_FUEL_THRESHOLDS[FireSize.Small]):
			change_fire_size(FireSize.Small)
		else:
			change_fire_size(FireSize.Tiny)
	else:
		change_fire_size(FireSize.Extinguished)
		_burn_timer.stop()
		_fire_sfx.stop()
		_embers_smoke_timer.start()
		
func _on_embers_smoke_timer_timeout() -> void:
	_smoke.amount_ratio -= 0.03
	clamp(_smoke.amount_ratio, 0, 1)

func change_fire_size(new_size: FireSize) -> void:
	if (current_size == new_size):
		pass
	
	match new_size:
		FireSize.Large:
			_sprite.play("burn_1")
			# This offset SHOULD have been baked into the sprite,
			# but what are you gonna do?
			_sprite.position.y = -13
			_smoke.amount_ratio = 0.2
			_fire_sfx.volume_db = 1.0
		FireSize.Medium:
			_sprite.play("burn_2")
			_sprite.position.y = -10
			_smoke.amount_ratio = 0.3
			_fire_sfx.volume_db = 0.5
		FireSize.Small:
			_sprite.play("burn_4")
			_sprite.position.y = -8
			_smoke.amount_ratio = 0.5
			_fire_sfx.volume_db = 0.0
		FireSize.Tiny:
			_sprite.position.y = -2
			_sprite.play("burn_5")
			_smoke.amount_ratio = 0.6
			_fire_sfx.volume_db = -1.0
		FireSize.Extinguished:
			_sprite.stop()
			_smoke.amount_ratio = 1.0
