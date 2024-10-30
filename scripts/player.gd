extends CharacterBody2D
class_name Player

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _action_cooldown: Timer = $ActionCooldownTimer
@onready var _snow_effect: ColorRect = $ColorRect
@onready var _footsteps_sfx: AudioStreamPlayer = $FootstepsSFX

var speed: int = 100
var is_dead: bool = false
var is_sprite_flipped: bool = false

signal move(x: float, y: float)
signal leave_print(pos: Vector2, angle: float)

func _ready():
	var screen_size: Vector2 = get_viewport().get_visible_rect().size

func _physics_process(_delta: float):
	if (!is_dead):
		handle_movement()
	_sprite.flip_h = is_sprite_flipped
		
func handle_movement():
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_dir.normalized() * speed
	
	#_sprite.flip_h = input_dir.x < 0
	
	if (velocity != Vector2.ZERO):
		_sprite.play("walk")
		if (!_footsteps_sfx.playing):
			_footsteps_sfx.play()
		
		# If walking left - flip the sprite horizontally
		if (velocity.x < 0):
			is_sprite_flipped = true
		# If walking left - unflip the sprite horizontally
		elif (velocity.x > 0):
			is_sprite_flipped = false
		# If velocity.x == 0 (walking straight up or down),
		# keep the sprite orientation whatever it was
	else:
		_sprite.play("idle")
		_footsteps_sfx.stop()
	move_and_slide()
	#debug
	move.emit(position.x, position.y)

func _on_footprint_timer_timeout() -> void:
	if (velocity != Vector2.ZERO):
		leave_print.emit(position, velocity.angle())
