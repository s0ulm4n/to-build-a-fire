class_name World
extends Node2D

## Main game node.
##
## Handles keeping track of and updating game state.

const WORLD_HEIGHT: int = 256
const WORLD_WIDTH: int = 256

const GAME_LENGTH: int = 359

const DAWN_START_TIME: int = 120
const DAWN_FINAL_RGB_MODULATION := 0.6

const BLIZZARD_CALM_TIME: int = 150
const BLIZZARD_START_SLANT := 0.9
const BLIZZARD_CALM_SLANT := 0.3
const BLIZZARD_START_BASE_SPEED := 0.8
const BLIZZARD_CALM_BASE_SPEED := 0.3
const BLIZZARD_START_ADDL_SPEED := 0.8
const BLIZZARD_CALM_ADDL_SPEED := 0.3

@export var wood_pickup_scene: PackedScene
@export var fire_scene: PackedScene
@export var footprint_scene: PackedScene

# Player warmth acts as HP. Reaching results in a game over.
var _warmth: int:
	set(value):
		_warmth = clamp(value, 0, 100)
		hud.update_warmth_label(_warmth)
		if _warmth == 0:
			_game_over(false)

# Wood is used to refuel burning fires or start new ones.
# Replenished by picking up logs.
var _wood_count: int:
	set(value):
		_wood_count = value
		hud.update_wood_count_label(_wood_count)

# Matches are used to start new fires (also consumes 1 wood).
# Matches can't be replenished.
var _matches_count: int:
	set(value):
		_matches_count = value
		hud.update_matches_count_label(_matches_count)

# Represents the length of time (in seconds) the player needs to stay alive
# in order to win the game.
var _time_left_to_win: int:
	set(value):
		_time_left_to_win = value
		hud.update_time_to_win_label(_time_left_to_win)
		if _time_left_to_win == 0:
			_game_over(true)
		
# When spawning player footprints, this affects whether the footprint sprite
# should be mirrored (as in left foot VS right foot)
var _flip_footprint: bool:
	get:
		# Flip the footprint every time we access the property
		_flip_footprint = !_flip_footprint
		return _flip_footprint

# When the player is next to a fire, this stores the reference to that fire
# so that we could trigger refueling.
var _nearby_fire: Fire

# These will be needed to modify the darkness effect over time
var _darkness_modulation_step: float

# These will be needed to modify the blizzard effect over time
var _blizzard_slant_step: float
var _blizzard_base_rain_speed_step: float
var _blizzard_additional_rain_speed_step: float

@onready var player: Player = $Player
@onready var terrain: TileMapLayer = $TerrainTileMapLayer
@onready var darkness_effect: CanvasModulate = $DarknessEffect

@onready var hud: HUD = $HUD

@onready var warmth_timer: Timer = $WarmthTimer
@onready var win_timer: Timer = $WinTimer
@onready var blizzard_calming_timer: Timer = $BlizzardCalmingTimer

@onready var blizzard_sfx: AudioStreamPlayer = $BlizzardSFX
@onready var wood_pickup_sfx: AudioStreamPlayer = $WoodPickupSFX

func _init() -> void:
	_darkness_modulation_step = DAWN_FINAL_RGB_MODULATION / DAWN_START_TIME
	
	_blizzard_slant_step = (BLIZZARD_START_SLANT - BLIZZARD_CALM_SLANT) / BLIZZARD_CALM_TIME
	_blizzard_base_rain_speed_step = (BLIZZARD_START_BASE_SPEED - BLIZZARD_CALM_BASE_SPEED) / BLIZZARD_CALM_TIME
	_blizzard_additional_rain_speed_step = (BLIZZARD_START_ADDL_SPEED - BLIZZARD_CALM_ADDL_SPEED) / BLIZZARD_CALM_TIME

func _ready() -> void:
	# Initialize game state
	_warmth = 100
	_wood_count = 0
	_matches_count = 3
	_time_left_to_win = GAME_LENGTH
	
	# Generate snow tiles
	for x in range(-WORLD_WIDTH / 2, WORLD_WIDTH / 2):
		for y in range(-WORLD_HEIGHT / 2, WORLD_HEIGHT / 2):
			# For now we're only using one terrain tile
			terrain.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)


func _input(event: InputEvent):
	# Actions processed here don't require a cooldown, because this
	# will be called ONCE PER KEYPRESS.
	# Earlier I was handling inputs in _process, which meant I had to
	# have a dedicated cooldown timer, because otherwise the actions
	# triggered every frame while the button was pressed.
	if event.is_action_pressed("refuel_fire"):
		player_action_refuel_fire()
	elif event.is_action_pressed("spawn_fire"):
		player_action_spawn_fire()

## Timers ##

func _on_warmth_timer_timeout():
	if _nearby_fire && _nearby_fire.fuel > 0:
		_warmth += 1
	else:
		_warmth -= 1
	
	if _warmth > 80:
		hud.frost_shader.visible = false
	else:
		hud.frost_shader.visible = true
		hud.frost_shader.queue_redraw()
		var frostyness := 0.5 + (80 - _warmth) / 20
			
		hud.frost_shader.material.set_shader_parameter(
			"frostyness",
			frostyness
		)


func _on_win_timer_timeout():
	_time_left_to_win -= 1
	
	if _time_left_to_win < DAWN_START_TIME:
		# The darkness is receding
		var time := DAWN_START_TIME - _time_left_to_win
		
		darkness_effect.color.r = _darkness_modulation_step * time
		darkness_effect.color.g = _darkness_modulation_step * time
		darkness_effect.color.b = _darkness_modulation_step * time
		
		# Reduce the intensity of the light circling the player
		# twice as fast as reducing the darkness modulation effect
		player.light.color.a = max(
				player.light.color.a - 2 * _darkness_modulation_step, 
				0,
		)
	
	if _time_left_to_win < BLIZZARD_CALM_TIME:
		if blizzard_calming_timer.is_stopped():
			blizzard_calming_timer.start()


func _on_blizzard_calming_timer_timeout() -> void:
	# The blizzard is dying down
	var time := BLIZZARD_CALM_TIME - _time_left_to_win
	
	hud.snow_effect.material.set_shader_parameter(
		"slant",
		BLIZZARD_START_SLANT - _blizzard_slant_step * time,
	)
	hud.snow_effect.material.set_shader_parameter(
		"base_rain_speed",
		BLIZZARD_START_BASE_SPEED - _blizzard_base_rain_speed_step * time,
	)
	hud.snow_effect.material.set_shader_parameter(
		"base_rain_speed",
		BLIZZARD_START_ADDL_SPEED - _blizzard_additional_rain_speed_step * time,
	)

## End Timers ##

## Player actions ##

func player_action_refuel_fire() -> void:
	if _wood_count > 0 && _nearby_fire != null:
		_wood_count -= 1
		_nearby_fire.fuel += Fire.FUEL_FROM_LOG


func player_action_spawn_fire() -> void:
	# We don't want to spawn fires too close to each other
	if _matches_count > 0 && _wood_count > 0 && _nearby_fire == null:
		_matches_count -= 1
		_wood_count -= 1
		
		var spawned_fire: Fire = fire_scene.instantiate()
		spawned_fire.position = player.position
		spawned_fire.visible = true
		spawned_fire.connect("enter_warm_zone", _on_fire_enter_warm_zone)
		spawned_fire.connect("exit_warm_zone", _on_fire_exit_warm_zone)
		
		add_child.call_deferred(spawned_fire)

## End Player actions ##

## Fire signals

func _on_fire_enter_warm_zone(fire: Fire) -> void:
	_nearby_fire = fire
	blizzard_sfx.volume_db = -3.0


func _on_fire_exit_warm_zone(fire: Fire) -> void:
	if _nearby_fire == fire:
		_nearby_fire = null
	blizzard_sfx.volume_db = 0.0

## End Fire signals ##

## Player signals ##

func _on_player_leave_print(pos: Vector2, angle: float) -> void:
	var footprint: Sprite2D = footprint_scene.instantiate()
	footprint.position = pos + Vector2(0, 14)
	footprint.rotation += angle
	footprint.visible = true
	
	if _flip_footprint:
		footprint.flip_h = true
	
	# This didn't work when I was just calling add_child(spawned_log)
	# See https://forum.godotengine.org/t/packedscene-instance-not-working-in-ready-function/2339/2
	add_child.call_deferred(footprint)


# debug
func _on_player_move(x: float, y: float) -> void:
	#hud.update_coord_label(round(x), round(y))
	pass

## End Player signals ##

## Other signals ##

func _on_log_pickup() -> void:
	_wood_count += 1
	wood_pickup_sfx.play()
	hud.update_wood_count_label(_wood_count)
	

func _on_tree_tile_map_layer_spawn_log(x: float, y: float) -> void:
	var spawned_log: Area2D = wood_pickup_scene.instantiate()
	spawned_log.position = Vector2(x, y)
	# Not sure why the log isn't spawned visible
	spawned_log.visible = true
	# Without this picking up the log doesn't trigger actually
	# updating the logs_count variable
	spawned_log.connect("pickup", _on_log_pickup)
	
	# This didn't work when I was just calling add_child(spawned_log)
	# See https://forum.godotengine.org/t/packedscene-instance-not-working-in-ready-function/2339/2
	add_child.call_deferred(spawned_log)

## End other signals ##

## Misc ##

func _game_over(did_win: bool) -> void:
	if did_win:
		hud.game_over_label.text = "The blizzard is over!\nYou survived!"
	else:
		hud.game_over_label.text = "Game Over\nYou froze :("
	
	warmth_timer.stop()
	player.is_dead = true
	hud.warmth_label.visible = false
	hud.wood_count_label.visible = false
	hud.time_to_win_label.visible = false
	hud.matches_count_label.visible = false
	
	hud.game_over_label.visible = true

## End Misc ##
