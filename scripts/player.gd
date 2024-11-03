class_name Player
extends CharacterBody2D

## Player character class.
##
## Handles player movement and sprite animation.

#signal debug_move(x: float, y: float)
signal leave_print(pos: Vector2, angle: float)

const PLAYER_SPEED: int = 100

var is_dead := false

var _is_sprite_flipped := false

@onready var sprite: AnimatedSprite2D = $PlayerSprite
@onready var footsteps_sfx: AudioStreamPlayer = $FootstepsSFX
@onready var light: PointLight2D = $PointLight2D

func _physics_process(_delta: float):
	if !is_dead:
		handle_movement()
	sprite.flip_h = _is_sprite_flipped


func handle_movement():
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_dir.normalized() * PLAYER_SPEED
	
	if velocity != Vector2.ZERO:
		sprite.play("walk")
		if !footsteps_sfx.playing:
			footsteps_sfx.play()
		
		# If walking left - flip the sprite horizontally
		if velocity.x < 0:
			_is_sprite_flipped = true
		# If walking right - unflip the sprite
		elif velocity.x > 0:
			_is_sprite_flipped = false
		# If velocity.x == 0 (walking straight up or down),
		# keep the sprite orientation whatever it was
	else:
		sprite.play("idle")
		footsteps_sfx.stop()
	move_and_slide()

	#debug_move.emit(position.x, position.y)


func _on_footprint_timer_timeout() -> void:
	if velocity != Vector2.ZERO:
		leave_print.emit(position, velocity.angle())
