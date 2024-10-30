extends Node2D
class_name World

const WORLD_HEIGHT = 256
const WORLD_WIDTH = 256

@export var _log_scene: PackedScene
@export var _fire_scene: PackedScene
@export var _footprint_scene: PackedScene

@onready var _hud: HUD = $HUD
@onready var _warmth_timer: Timer = $WarmthTimer
@onready var _win_timer: Timer = $WinTimer

@onready var _player: Player = $Player
@onready var _terrain: TileMapLayer = $TerrainTileMapLayer

@onready var _blizzard_sfx: AudioStreamPlayer = $BlizzardSFX
@onready var _wood_pickup_sfx: AudioStreamPlayer = $WoodPickupSFX

var warmth: int = 100
var logs_count: int = 0
var matches_count: int = 3
var hours_left_to_win: int = 6

var nearby_fire: Fire

var flip_footprint: bool = false

func _ready() -> void:
	# Setup warmth timer.
	# This can be done vie the Timer Node settings, but it feels
	# more intuitive to do this here explicitly.
	#_warmth_timer.wait_time = 1 # 1 second
	_warmth_timer.connect("timeout", _on_warmth_timer_timeout)
	_warmth_timer.start()
	
	_win_timer.wait_time = 60 # 1 minute = 1 hour in-game
	_win_timer.connect("timeout", _on_win_timer_timeout)
	_win_timer.start()
	
	for x in range(-WORLD_WIDTH / 2, WORLD_WIDTH / 2):
		for y in range(-WORLD_HEIGHT / 2, WORLD_HEIGHT / 2):
			_terrain.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)

func _process(_delta: float) -> void:
	_hud.update_warmth_label(warmth)
	_hud.update_logs_count_label(logs_count)
	_hud.update_matches_count_label(matches_count)
	_hud.update_time_to_win_label(hours_left_to_win)
	
	if (hours_left_to_win == 0):
		game_over(true)
	
	if (warmth == 0):
		game_over(false)
		
func _input(event: InputEvent):
	# Actions processed here don't require a cooldown, because this
	# will be called ONCE PER KEYPRESS.
	# Earlier I was handling inputs in _process, which meant I had to
	# have a dedicated cooldown timer, because otherwise the actions
	# triggered every frame while the button was pressed.
	if (event.is_action_pressed("refuel_fire")):
		player_action_refuel_fire()
	elif (event.is_action_pressed("spawn_fire")):
		player_action_spawn_fire()

## Timers ##

func _on_warmth_timer_timeout():
	if nearby_fire && nearby_fire.fuel > 0:
		warmth += 1
	else:
		warmth -= 1
	warmth = clamp(warmth, 0, 100)
	
	if (warmth > 80):
		_hud._frost_shader.visible = false
	else:
		_hud._frost_shader.visible = true
		_hud._frost_shader.queue_redraw()
		var frostyness = 0.5 + (80 - warmth) / 20
			
		_hud._frost_shader.material.set_shader_parameter(
			"frostyness",
			frostyness
		)
	
func _on_win_timer_timeout():
	hours_left_to_win -= 1

## End Timers ##

## Player actions ##

func player_action_refuel_fire() -> void:
	if (logs_count > 0 && nearby_fire != null):
		logs_count -= 1
		nearby_fire.fuel += Fire.FUEL_FROM_LOG
		
func player_action_spawn_fire() -> void:
	# We don't want to spawn fires too close to each other
	if (matches_count > 0 && logs_count > 0 && nearby_fire == null):
		matches_count -= 1
		logs_count -= 1
		
		var spawned_fire: Fire = _fire_scene.instantiate()
		spawned_fire.position = _player.position
		spawned_fire.visible = true
		spawned_fire.connect("enter_warm_zone", _on_fire_enter_warm_zone)
		spawned_fire.connect("exit_warm_zone", _on_fire_exit_warm_zone)
		
		add_child.call_deferred(spawned_fire)

## End Player actions ##

## Fire signals

func _on_fire_enter_warm_zone(fire: Fire) -> void:
	nearby_fire = fire
	_blizzard_sfx.volume_db = -3.0

func _on_fire_exit_warm_zone(fire: Fire) -> void:
	if (nearby_fire == fire):
		nearby_fire = null
	_blizzard_sfx.volume_db = 0.0

## End Fire signals ##

## Player signals ##
		
func _on_player_leave_print(pos: Vector2, angle: float) -> void:
	var footprint: Sprite2D = _footprint_scene.instantiate()
	footprint.position = pos + Vector2(0, 14)
	footprint.rotation += angle
	if (flip_footprint):
		footprint.flip_h = true
	flip_footprint = !flip_footprint
	# Not sure why the log isn't spawned visible
	footprint.visible = true
	
	# This didn't work when I was just calling add_child(spawned_log)
	# See https://forum.godotengine.org/t/packedscene-instance-not-working-in-ready-function/2339/2
	add_child.call_deferred(footprint)

# debug
func _on_player_move(x: float, y: float) -> void:
	_hud.update_coord_label(round(x), round(y))

## End Player signals ##

## Other signals ##

func _on_log_pickup() -> void:
	logs_count += 1
	_wood_pickup_sfx.play()
	_hud.update_logs_count_label(logs_count)

func _on_tree_tile_map_layer_spawn_log(x: float, y: float) -> void:
	var spawned_log: Area2D = _log_scene.instantiate()
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

func game_over(did_win: bool) -> void:
	if (did_win):
		_hud.set_game_over_label_text("The blizzard is over!\nYou survived!")
	else:
		_hud.set_game_over_label_text("Game Over\nYou froze :(")
	
	_warmth_timer.stop()
	_player.is_dead = true
	_hud._warmth_label.visible = false
	_hud._logs_count_label.visible = false
	_hud._time_to_win_label.visible = false
	_hud._matches_count_label.visible = false
	
	_hud._game_over_label.visible = true

## End Misc ##
