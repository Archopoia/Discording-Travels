extends RigidBody2D  # Assuming PioneerPixel is a RigidBody2D
class_name PioneerPixel

var target_tile_position: Vector2  # The position to move the PioneerPixel to

# Moves the PioneerPixel to the new tile's position
func move_to_tile(tile_global_position: Vector2) -> void:
	# Set the global position of the PioneerPixel to the new tile's position
	global_position = tile_global_position
