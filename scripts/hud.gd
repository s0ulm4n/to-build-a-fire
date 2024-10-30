extends CanvasLayer
class_name HUD

@onready var _warmth_label: Label = $WarmthLabel
@onready var _game_over_label: Label = $GameOverLabel
@onready var _logs_count_label: Label = $LogsCountLabel
@onready var _matches_count_label: Label = $MatchesCountLabel
@onready var _coord_label: Label = $CoordLabel
@onready var _time_to_win_label: Label = $TimeToWinLabel
@onready var _game_paused_label: Label = $GamePausedLabel

@onready var _frost_shader: TextureRect = $FrostShaderTextureRect

func _ready() -> void:
	_frost_shader.size = DisplayServer.window_get_size()

func _input(event: InputEvent) -> void:
	# This input is handled here (as opposed to the main node, like the rest)
	# because once the game is paused, the main node STOPS BEING PROCESSED!
	# The HUD node is explicitly set to Always get processed, so pausing the
	# game doesn't affect it.
	# Note: the HUD _NODE_ that is a child of the main node should be set to
	# always get processed, NOT the root node of the HUD _SCENE_. The latter
	# won't do anything!
	if (event.is_action_pressed("pause")):
		var should_pause = !get_tree().paused
		get_tree().paused = should_pause
		_game_paused_label.visible = should_pause

func update_warmth_label(warmth: int) -> void:
	_warmth_label.text = str("Warmth: ", warmth)

func update_logs_count_label(logs_count: int) -> void:
	_logs_count_label.text = str("Wood: ", logs_count)

func update_coord_label(x: float, y: float) -> void:
	_coord_label.text = str("(", x, ", ", y, ")")

func update_matches_count_label(matches_count: int) -> void:
	_matches_count_label.text = str("Matches: ", matches_count)

func update_time_to_win_label(hours_left: int) -> void:
	_time_to_win_label.text = str("Blizzard ends in ", hours_left, " hours")

func set_game_over_label_text(text: String) -> void:
	_game_over_label.text = text
