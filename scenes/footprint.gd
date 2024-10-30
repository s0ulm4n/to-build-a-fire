extends Sprite2D
class_name Footprint

func _process(delta: float) -> void:
	self_modulate.a = self_modulate.a - 0.005

func _on_life_timer_timeout() -> void:
	queue_free()
