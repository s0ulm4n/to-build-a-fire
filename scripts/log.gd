extends Area2D
class_name Log

signal pickup

func _on_body_entered(body: Node2D) -> void:
	if (body is Player):
		pickup.emit()
		queue_free()
