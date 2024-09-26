class_name HandlerResources
extends Node

## Singleton reference
static var ref : HandlerResources
var log_scene = preload("res://scenes/user_interface/log.tscn")  # Load the log.tscn scene
var pioneer_pixel_scene = preload("res://scenes/PioneerPixel.tscn")  # Preload the PioneerPixel scene
var request_shown = false
var pioneer_label_shown = false

# Store a reference to the spawned PioneerPixel instances
var pioneer_pixels: Array = []
# Define a reference to the map script (for colony tile position)


## Assigns itself if there is no ref, and otherwise, destroy it (singleton check)
func _enter_tree() -> void:
	if not ref:
		ref = self
		return
	queue_free()

## Dictionary to hold different resource types and their quantities
var resources : Dictionary = {
	"Knowledge": 0,
	"Wood": 0,
	"Pioneers": 1
}

## Dictionary to hold situations (booleans)
var situations : Dictionary = {
	"outpost_built": false,
	"colony_prosperous": false
}

## Signals for resource creation and consumption
signal resource_created(resource_type : String, quantity : int)
signal resource_consumed(resource_type : String, quantity : int)

var map_node: Node = null

# Function to hide the Request container on game launch
func _ready():
	# Get the Request container from the "requests" group
	var requests_group = get_tree().get_nodes_in_group("requests")
	for request_container in requests_group:
		request_container.visible = false  # Make sure the Request container is hidden when the game launches
	# Find the TabContainer
	var tab_container = get_node("/root/Game/HUD/UserInterface/VBoxContainer/Bottom/RightPanel/Tabs/TabContainer")
	
	# Connect the tab_changed signal
	tab_container.connect("tab_changed", Callable(self, "_on_tab_changed"))
	# Set visibility based on the current tab when the scene loads
	_on_tab_changed(tab_container.current_tab)
	# Defer the node access until everything is ready

	_check_resource_conditions()

func _process(delta: float) -> void:
	_check_resource_conditions()  # Continuously check the state of resources
	
	## This function checks the state of resources and updates UI elements accordingly
func _check_resource_conditions() -> void:
	var current_pioneer_count = resources["Pioneers"]
	# Adjust PioneerPixel instances based on the number of pioneers
	adjust_pioneer_pixel_count(current_pioneer_count)
	
	# Check if Knowledge has reached 10 for the first time and show request
	if resources.has("Knowledge") and resources["Knowledge"] >= 1 and not request_shown:
		# Get the Request container from the "requests" group
		var requests_group = get_tree().get_nodes_in_group("requests")
		for request_container in requests_group:
			# Set the Request container and VBoxContainer to visible
			request_container.visible = true

			# Get the VBoxContainer inside the Request container
			var vbox = request_container.get_node("VBoxContainer")
			vbox.visible = true  # Set VBoxContainer to visible

			# Make specific children inside VBoxContainer visible
			vbox.get_node("Label").visible = true
			vbox.get_node("HSeparator").visible = true
			vbox.get_node("GetPioneer").visible = true

			# Ensure that GetPioneer2 remains hidden
			vbox.get_node("Button2").visible = false

		send_to_chatlog("Request container and specific elements are now visible.")

		# Mark that the request container has been shown, so this doesn't repeat
		request_shown = true

	# Check if Pioneer count is greater than or equal to 2 and show the label
	if resources.has("Pioneers") and resources["Pioneers"] >= 2 and not pioneer_label_shown:
		# Get all nodes in the "resources" group
		var resources_group = get_tree().get_nodes_in_group("resources")
		for node in resources_group:
			# Ensure we're affecting the "Pioneers" label
			if node.name == "Pioneers":
				node.visible = true  # Show the Pioneers label

		# Mark that the pioneer label has been shown, so this doesn't repeat
		pioneer_label_shown = true


## Returns the current amount of a specific resource
func get_resource(resource_type: String) -> int:
	if resources.has(resource_type):
		return resources[resource_type]
	else:
		return 0  # Return 0 if the resource type doesn't exist

## Creates a specific amount of a resource (or increases it)
func create_resource(resource_type: String, quantity: int) -> void:
	if resources.has(resource_type):
		resources[resource_type] += quantity
	else:
		# If the resource type doesn't exist, initialize it
		resources[resource_type] = quantity
	
	resource_created.emit(resource_type, quantity)
	_check_resource_conditions()  # Check immediately after updating the resource
	# Trigger event checks after resource update
	get_node("/root/Game/Handlers/Events").check_events()

## Consumes a specific amount of a resource
## Returns "Error" if not enough resource is available
func consume_resource(resource_type: String, quantity: int) -> Error:
	if resources.has(resource_type) and resources[resource_type] >= quantity:
		resources[resource_type] -= quantity
		resource_consumed.emit(resource_type, quantity)

		# Trigger event checks after resource update
		get_node("/root/Game/Handlers/Events").check_events()

		return OK
	else:
		send_to_chatlog("Not enough " + resource_type + "...")
		return FAILED  # Not enough of the resource to consume

## NEW FUNCTION: Update (adjust) a resource by a specific value
func update_resource(resource_type: String, adjustment: int) -> void:
	# Check if the resource exists, then adjust the value by the specified amount
	if resources.has(resource_type):
		resources[resource_type] += adjustment  # Add or subtract the adjustment amount
	else:
		# If the resource doesn't exist, initialize it with the adjustment amount
		resources[resource_type] = adjustment

	resource_created.emit(resource_type, adjustment)


	# Send resource update to chat log
	send_to_chatlog("Resource update: " + resource_type + " changed by " + str(adjustment) + ". New value: " + str(resources[resource_type]))

	# Trigger event checks after resource update
	get_node("/root/Game/Handlers/Events").check_events()

# Adjusts the number of PioneerPixel instances to match the "Pioneers" resource quantity
func adjust_pioneer_pixel_count(desired_count: int) -> void:
	# Adjust the count to be X-1 instead of X
	var target_count = max(0, desired_count - 1)  # Ensure we don't go below 0

	var current_count = pioneer_pixels.size()
	
	# If we need to add more pioneers
	if target_count > current_count:
		for i in range(current_count, target_count):
			spawn_pioneer_pixel()
	
	# If we need to remove pioneers
	elif target_count < current_count:
		for i in range(current_count - target_count):
			despawn_oldest_pioneer_pixel()

# Function to find the index of the "Exploration" tab by its name
func _get_exploration_tab_index(tab_container: TabContainer) -> int:
	for i in range(tab_container.get_tab_count()):
		if tab_container.get_tab_title(i) == "Exploration":
			return i
	return -1  # Return -1 if the tab isn't found

# Function to toggle visibility based on the selected tab
func _on_tab_changed(tab_index: int) -> void:
	var tab_container = get_node("/root/Game/HUD/UserInterface/VBoxContainer/Bottom/RightPanel/Tabs/TabContainer")
	
	# Find the index of the "Exploration" tab
	var exploration_index = _get_exploration_tab_index(tab_container)
	if exploration_index == -1:
		print("Exploration tab not found!")
		return

	var pioneers_node = get_node_or_null("/root/Game/HUD/UserInterface/VBoxContainer/Bottom/RightPanel/Tabs/TabContainer/Exploration/VBoxContainer/Pioneers")
	
	if pioneers_node:
		# Show or hide the pioneers node based on whether the "Exploration" tab is selected
		pioneers_node.visible = (tab_index == exploration_index)
		
# Function to spawn PioneerPixel instances in the "Pioneers" node
# Spawn a PioneerPixel instance in the colony tile
# Spawn a PioneerPixel instance in the colony tile
func spawn_pioneer_pixel() -> void:
	# Instantiate the PioneerPixel
	var pioneer_pixel = pioneer_pixel_scene.instantiate()
	map_node = get_node_or_null("/root/Game/HUD/UserInterface/VBoxContainer/Bottom/RightPanel/Tabs/TabContainer/Exploration/VBoxContainer/Map")
	var tile_size = map_node.tile_size
	# Generate a random offset within the colony tile (to avoid overlap)
	var random_pos = Vector2(randf_range(0, tile_size.x - 4), randf_range(0, tile_size.y - 4))

	# Set the global position of the PioneerPixel relative to the colony tile's global position
	pioneer_pixel.global_position = random_pos + Vector2(790, -475)
	pioneer_pixel.z_index = 11  # Ensure it is drawn on the topmost layer

	# Add the PioneerPixel to the "Pioneers" node
	var pioneers_node = get_node_or_null("/root/Game/HUD/UserInterface/VBoxContainer/Bottom/RightPanel/Tabs/TabContainer/Exploration/VBoxContainer/Pioneers")
	
	if pioneers_node:
		pioneers_node.add_child(pioneer_pixel)
	else:
		print("Pioneers node not found!")
	
	# Store the spawned PioneerPixel in the list
	pioneer_pixels.append(pioneer_pixel)


# Removes the earliest spawned PioneerPixel
func despawn_oldest_pioneer_pixel() -> void:
	if pioneer_pixels.size() > 0:
		var oldest_pioneer = pioneer_pixels[0]
		oldest_pioneer.queue_free()  # Remove it from the scene
		pioneer_pixels.remove_at(0)  # Remove from the list

# Checks if a position overlaps with an existing pioneer
func _position_overlaps(position: Vector2) -> bool:
	for pioneer in pioneer_pixels:
		if pioneer.position.distance_to(position) < 4:  # Ensure there's at least 4-pixel distance
			return true
	return false



## NEW FUNCTION: Updates a situation
func update_situation(situation_name: String, state: bool) -> void:
	if situations.has(situation_name):
		situations[situation_name] = state

	# Send situation update to chat log
	send_to_chatlog("Situation update: " + situation_name + " is now " + str(state))

	# Trigger event checks after situation change
	get_node("/root/Game/Handlers/Events").check_events()

# Function to send messages to the chat log using log.tscn
func send_to_chatlog(message: String):
	var chat_log = get_tree().get_nodes_in_group("chat_log")[0] if get_tree().has_group("chat_log") else null
	if chat_log:
		var new_message = log_scene.instantiate()  # Instance the log.tscn scene
		if new_message:  # Check if instantiation was successful
			new_message.text = message  # Directly set the message text because new_message is a Label
			chat_log.add_child(new_message)  # Add it to the chat log
			chat_log.move_child(new_message, 0)  # Move it to the top of the chat log
		else:
			print("Failed to instance log.tscn")
