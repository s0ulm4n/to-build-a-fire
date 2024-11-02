class_name Footprint
extends Sprite2D

## A class for the footprints left behind when the player walks around.

func _process(delta: float) -> void:
	# Footprints should fade out over time
	self_modulate.a -= 0.005


func _on_life_timer_timeout() -> void:
	# Delete the footpring node once it fully fades
	queue_free()
