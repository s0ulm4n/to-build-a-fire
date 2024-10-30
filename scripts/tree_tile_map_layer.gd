extends TileMapLayer

#const SIZE_X: int = 128
#const SIZE_Y: int = 128
const TREE_THRESHOLD: float = 0.2
const LOG_THRESHOLD: float = 0.995
#const TREE_TILE_WIDTH: int = 38
#const TREE_TILE_HEIGHT: int = 64

@export var noise_texture: NoiseTexture2D

signal spawn_log(x: float, y: float)

var noise
#debug
#var values_array = []

func _ready() -> void:
	noise = noise_texture.noise
	
	for x in range(-World.WORLD_WIDTH / 2, World.WORLD_WIDTH / 2):
		for y in range(-World.WORLD_HEIGHT / 2, World.WORLD_HEIGHT / 2):
			# This is very weird and needs to be rewritten
			var temp = noise.get_noise_2d(x, y) * -1
			# debug
			# values_array.append(temp)
			# print(temp)
			if (temp > TREE_THRESHOLD):
				var tree_atlas_num: int
				if (randf() > 0.5): 
					tree_atlas_num = 0
				else:
					tree_atlas_num = 1
				set_cell(Vector2i(x, y), tree_atlas_num, Vector2i.ZERO)
				
				#debug
				#print("Planting a tree at cell (", x, ", ", y, ")")
			else:
				if (randf() > LOG_THRESHOLD):
					# print("Spawning a log at (", x * TILE_WIDTH, ", ", y * TILE_HEIGHT, ")");
					spawn_log.emit(x * 16, y * 16)
	# debug
	#print("min: ", values_array.min())
	#print("max: ", values_array.max())
