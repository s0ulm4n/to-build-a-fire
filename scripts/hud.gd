class_name HUD
extends CanvasLayer

## User interface layer

@onready var warmth_label: Label = $WarmthLabel
@onready var game_over_label: Label = $GameOverLabel
@onready var wood_count_label: Label = $LogsCountLabel
@onready var matches_count_label: Label = $MatchesCountLabel
@onready var coord_label: Label = $CoordLabel
@onready var time_to_win_label: Label = $TimeToWinLabel
@onready var game_paused_label: Label = $GamePausedLabel

@onready var frost_shader: TextureRect = $FrostShaderTextureRect

func _ready() -> void:
	frost_shader.size = DisplayServer.window_get_size()


func _input(event: InputEvent) -> void:
	# This input is handled here (as opposed to the main node, like the rest)
	# because once the game is paused, the main node STOPS BEING PROCESSED!
	# The HUD node is explicitly set to Always get processed, so pausing the
	# game doesn't affect it.
	# Note: the HUD _NODE_ that is a child of the main node should be set to
	# always get processed, NOT the root node of the HUD _SCENE_. The latter
	# won't do anything!
	if event.is_action_pressed("pause"):
		var should_pause = !get_tree().paused
		get_tree().paused = should_pause
		game_paused_label.visible = should_pause


func update_warmth_label(warmth: int) -> void:
	warmth_label.text = str("Warmth: ", warmth)


func update_wood_count_label(wood_count: int) -> void:
	wood_count_label.text = str("Wood: ", wood_count)


func update_coord_label(x: float, y: float) -> void:
	coord_label.text = str("(", x, ", ", y, ")")


func update_matches_count_label(matches_count: int) -> void:
	matches_count_label.text = str("Matches: ", matches_count)


func update_time_to_win_label(hours_left: int) -> void:
	time_to_win_label.text = str("Blizzard ends in ", hours_left, " hours")
