extends Control

var map_script  # Reference to the map script
# Reference to the label that will show the number of pioneers in this tile
@onready var pioneer_count_label = $PioneerCountLabel

# Track the number of pioneer pixels inside the tile
var pioneer_count = 0

func _ready():
	var button = $TileButton
	button.connect("mouse_entered", Callable(self, "_on_tile_mouse_entered"))
	button.connect("mouse_exited", Callable(self, "_on_tile_mouse_exited"))
	button.connect("pressed", Callable(self, "_on_tile_pressed"))
	
	# Connect the Area2D signals to detect when PioneerPixel enters/exits the tile
	var area = $Area2D
	area.connect("body_entered", Callable(self, "_on_body_entered"))
	area.connect("body_exited", Callable(self, "_on_body_exited"))

func _on_tile_mouse_entered() -> void:
	if map_script:
		var position = global_position  # Get the global position of the tile
		map_script.show_tooltip_at_position(position, "some biome information")  # Pass information needed

func _on_tile_mouse_exited() -> void:
	if map_script:
		map_script.hide_tooltip()

func _on_tile_pressed() -> void:
	if map_script:
		# Call the map script to move one of the PioneerPixels to this tile
		map_script.move_pioneer_to_tile(self)  # `self` is this tile

# Called when a body (PioneerPixel) enters the Area2D
func _on_body_entered(body):
	if body is PioneerPixel:
		pioneer_count += 1
		update_pioneer_count_label()

# Called when a body (PioneerPixel) exits the Area2D
func _on_body_exited(body):
	if body is PioneerPixel:
		pioneer_count -= 1
		update_pioneer_count_label()

# Update the label with the current number of pioneers
func update_pioneer_count_label():
	pioneer_count_label.text = str(pioneer_count)
