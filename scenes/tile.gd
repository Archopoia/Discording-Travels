extends Control

var map_script  # Reference to the map script (we will pass it when creating the tile)

func _ready():
	var button = $TileButton
	button.connect("mouse_entered", Callable(self, "_on_tile_mouse_entered"))
	button.connect("mouse_exited",  Callable(self, "_on_tile_mouse_exited"))
	button.connect("pressed", Callable(self, "_on_tile_pressed"))


func _on_tile_button_mouse_entered() -> void:
	if map_script:
		var position = global_position  # Get the global position of the tile
		map_script.show_tooltip_at_position(position, "some biome information")  # Pass information needed


func _on_tile_button_mouse_exited() -> void:
	if map_script:
		map_script.hide_tooltip()


func _on_tile_button_pressed() -> void:
	if map_script:
		# Get the tile's grid position and pass it to the map script
		map_script.tile_pressed(global_position)
