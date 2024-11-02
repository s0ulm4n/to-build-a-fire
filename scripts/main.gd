class_name World
extends Node2D

## Main game node.
##
## Handles keeping track of and updating game state.

const WORLD_HEIGHT: int = 256
const WORLD_WIDTH: int = 256

@export var wood_pickup_scene: PackedScene
@export var fire_scene: PackedScene
@export var footprint_scene: PackedScene

var _warmth: int = 100
var _wood_count: int = 0
var _matches_count: int = 3
var _hours_left_to_win: int = 6
var _flip_footprint: bool = false

var _nearby_fire: Fire

@onready var player: Player = $Player
@onready var terrain: TileMapLayer = $TerrainTileMapLayer

@onready var hud: HUD = $HUD

@onready var warmth_timer: Timer = $WarmthTimer
@onready var win_timer: Timer = $WinTimer

@onready var blizzard_sfx: AudioStreamPlayer = $BlizzardSFX
@onready var wood_pickup_sfx: AudioStreamPlayer = $WoodPickupSFX

func _ready() -> void:
	for x in range(-WORLD_WIDTH / 2, WORLD_WIDTH / 2):
		for y in range(-WORLD_HEIGHT / 2, WORLD_HEIGHT / 2):
			# For now we're only using one terrain tile
			terrain.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)

func _process(_delta: float) -> void:
	hud.update_warmth_label(_warmth)
	hud.update_wood_count_label(_wood_count)
	hud.update_matches_count_label(_matches_count)
	hud.update_time_to_win_label(_hours_left_to_win)
	
	if _hours_left_to_win == 0:
		_game_over(true)
	
	if _warmth == 0:
		_game_over(false)
		
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
	_warmth = clamp(_warmth, 0, 100)
	
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
	_hours_left_to_win -= 1

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
	if _flip_footprint:
		footprint.flip_h = true
	_flip_footprint = !_flip_footprint
	# Not sure why the log isn't spawned visible
	footprint.visible = true
	
	# This didn't work when I was just calling add_child(spawned_log)
	# See https://forum.godotengine.org/t/packedscene-instance-not-working-in-ready-function/2339/2
	add_child.call_deferred(footprint)

# debug
func _on_player_move(x: float, y: float) -> void:
	hud.update_coord_label(round(x), round(y))

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
