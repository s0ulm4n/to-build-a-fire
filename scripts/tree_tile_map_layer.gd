extends TileMapLayer

## Procedurally generated tile map.
## Also handles generating trees and spawning wood pickups.

signal spawn_log(x: float, y: float)

const TREE_GEN_THRESHOLD := 0.2
const LOG_GEN_THRESHOLD := 0.995

@export var noise_texture: NoiseTexture2D

var _noise: Noise

func _ready() -> void:
	_noise = noise_texture.noise
	
	for x in range(-World.WORLD_WIDTH / 2, World.WORLD_WIDTH / 2):
		for y in range(-World.WORLD_HEIGHT / 2, World.WORLD_HEIGHT / 2):
			# I find it easier to work with the noise values after
			# flipping their sign.
			var noise_value := _noise.get_noise_2d(x, y) * -1.0
			
			if noise_value > TREE_GEN_THRESHOLD:
				# Generate a tree in this cell
				
				# Pick the tree sprite to use
				var tree_atlas_num: int = 0 if randf() > 0.5 else 1
				
				set_cell(Vector2i(x, y), tree_atlas_num, Vector2i.ZERO)
			else:
				if randf() > LOG_GEN_THRESHOLD:
					# Spawn a log pickup
					spawn_log.emit(x * 16, y * 16)
