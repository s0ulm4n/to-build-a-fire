extends Area2D

## Log object the player can pick up to increase their wood supply.

signal pickup

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		pickup.emit()
		queue_free()
