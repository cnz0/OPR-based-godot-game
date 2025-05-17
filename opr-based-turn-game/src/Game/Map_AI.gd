extends TileMapLayer

var obstacle_sizes = [
	{"size": Vector2i(1, 1), "frequency": 2},
	{"size": Vector2i(2, 1), "frequency": 5},
	{"size": Vector2i(3, 1), "frequency": 10},
	{"size": Vector2i(1, 2), "frequency": 10},
	{"size": Vector2i(2, 2), "frequency": 5},
	{"size": Vector2i(3, 2), "frequency": 15},
	{"size": Vector2i(3, 3), "frequency": 8},
	{"size": Vector2i(2, 3), "frequency": 15},
	{"size": Vector2i(1, 3), "frequency": 8}
]

var size

var player_buttons = {1: [], 2: []}  # Buttons for both players
var current_player

var map_file_path

var max_rounds = 4
var current_round = 1
var units_player1 = []
var units_player2 = []

var victory_points = []
var point_status = {}

var ai_controller: AIController

var background_node: ColorRect

func _ready():
	# Istniejący kod generowania mapy i przeszkód...
	
	ai_controller = AIController.new(self)
	ai_controller.units = units_player2  # Przypisanie jednostek AI
	ai_controller.victory_points = victory_points  # Przypisanie punktów zwycięstwa
	add_child(ai_controller)  # Dodanie AIController jako dziecka sceny
	
	background_node = get_node("../Background")
	
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.frequency = 0.1
	size = 80
	
	for x in range(size):
		for y in range(size):
			var value = noise.get_noise_2d(x, y)
			if value < -0.3:
				set_cell(Vector2i(x, y), 0, Vector2i(3, 0))
			elif value > 0.3:
				set_cell(Vector2i(x, y), 0, Vector2i(1, 0))
			else:
				set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
				
	for x in range(size):
		for y in range(size):
			if randi() % 100 < 2:  # 5% chance to place an obstacle
				var obstacle = choose_obstacle()
				place_obstacle(obstacle, Vector2i(x, y))
	
	# Nowa część kodu: generowanie punktów zwycięstwa
	generate_victory_points()
	
func generate_victory_points():
	var num_points = randi() % 4 + 2  # Losuj liczbę punktów od 2 do 5
	var placed_points = []
	
	while placed_points.size() < num_points:
		var x = randi() % (68 - 12 + 1) + 12
		var y = randi() % (68 - 12 + 1) + 12
		var new_point = Vector2i(x, y)
		
		if is_valid_victory_point(new_point, placed_points):
			set_cell(new_point, 0, Vector2i(2, 0))  # Umieść punkt na mapie
			placed_points.append(new_point)
			victory_points.append(new_point)  # Dodaj punkt do listy
			point_status[new_point] = "neutral"  # Ustaw neutralny status
			
func is_valid_victory_point(point: Vector2i, existing_points: Array) -> bool:
	# Sprawdź, czy punkt znajduje się na wolnym polu
	if get_cell_atlas_coords(point) == Vector2i(4, 0):  # Przeszkoda
		return false
	
	# Sprawdź minimalną odległość od istniejących punktów
	for existing_point in existing_points:
		if abs(existing_point.x - point.x) < 6 and abs(existing_point.y - point.y) < 6:
			return false
	
	return true
	
func analyze_victory_points():
	var player1_units = get_unit_positions(1)
	var player2_units = get_unit_positions(2)
	
	for point in victory_points:
		var player1_nearby = is_unit_near_point(player1_units, point)
		var player2_nearby = is_unit_near_point(player2_units, point)
		
		# Sprawdź aktualny status punktu
		var current_status = point_status.get(point, "neutral")
		
		if player1_nearby and player2_nearby:
			point_status[point] = "contested"  # Kontestowany
		elif player1_nearby:
			point_status[point] = "player1"  # Przejęty przez gracza 1
		elif player2_nearby:
			point_status[point] = "player2"  # Przejęty przez gracza 2
		else:
			# Jeśli punkt był przejęty, zachowaj aktualny status
			if current_status in ["player1", "player2"]:
				continue  # Zachowaj istniejącego właściciela
			else:
				point_status[point] = "neutral"  # Ustaw jako neutralny
		
		# Zmień kolor punktu w zależności od statusu
		update_victory_point_color(point, point_status[point])
		
func is_unit_near_point(unit_positions: Array, point: Vector2i) -> bool:
	for unit in unit_positions:
		if abs(unit.x - point.x) <= 3 and abs(unit.y - point.y) <= 3:
			return true
	return false
	
func get_unit_positions(player: int) -> Array:
	var unit_positions = []
	var units = units_player1 if player == 1 else units_player2
	
	for unit in units:
		unit_positions.append(local_to_map(unit.position))
	
	return unit_positions
	
func update_victory_point_color(point: Vector2i, status: String):
	if status == "player1":
		set_cell(point, 0, Vector2i(6, 0))  # Czerwona poświata (np. inny tile w atlasie)
	elif status == "player2":
		set_cell(point, 0, Vector2i(7, 0))  # Niebieska poświata (np. inny tile w atlasie)
	elif status == "contested":
		set_cell(point, 0, Vector2i(5, 0))  # Poświata kontestowana (np. żółta)
	else:
		set_cell(point, 0, Vector2i(2, 0))  # Neutralny
				
func choose_obstacle():
	var total_frequency = 0
	for obs in obstacle_sizes:
		total_frequency += obs["frequency"]
	
	var rand = randi() % total_frequency
	var cumulative = 0
	
	for obs in obstacle_sizes:
		cumulative += obs["frequency"]
		if rand < cumulative:
			return obs["size"]
			
	return Vector2i(1, 1)
	
func place_obstacle(size: Vector2i, position: Vector2i):
	for dx in range(size.x):
		for dy in range(size.y):
			if is_within_bounds(position):
				set_cell(Vector2i(position.x + dx, position.y + dy), 0, Vector2i(4, 0))
			
func is_within_bounds(pos: Vector2i) -> bool:
	return pos.x > 2 and pos.y > 2 and pos.x < size-2 and pos.y < size-2
	
func update_background_color():
	if current_player == 1:
		background_node.modulate = Color(192 / 255.0, 128 / 255.0, 128 / 255.0)  # Czerwony odcień
	elif current_player == 2:
		background_node.modulate = Color(128 / 255.0, 128 / 255.0, 192 / 255.0)  # Niebieski odcień
	
func _on_save_game_button_pressed() -> void:
	var time = Time.get_datetime_dict_from_system()
	var timestamp = "%04d%02d%02d%02d%02d%02d" % [time.year, time.month, time.day, time.hour, time.minute, time.second]
	map_file_path = "res://Saves/" + timestamp + ".txt"
	var file = FileAccess.open(map_file_path, FileAccess.WRITE)
	if file:
		for x in range(size):
			for y in range(size):
				var source_id = get_cell_source_id(Vector2i(x, y))
				if source_id != -1:  # Checks if the cell is not empty
					var atlas_coords = get_cell_atlas_coords(Vector2i(x, y))
					file.store_line(str(x) + "," + str(y) + "," + str(atlas_coords))
		file.close()
		print("Map saved to ", map_file_path)
		$Camera2D.toggle_pause()  # Call the function
	else:
		print("Failed to open file for writing.")


func _on_load_game_button_pressed() -> void:
	pass # Replace with function body.


func _on_begin_game_pressed() -> void:
	$BeginGame.visible = false
	$UnitInfo.visible = true
	$GameLog.visible = true
	$EndTurn.visible = true
	
	dual_dice()

	var file_paths = [
		{"path": "res://temp/armies_hotseat_temp_one.txt", "x_offset": -300},  # Player 1
		{"path": "res://temp/armies_hotseat_temp_two.txt", "x_offset": 2600}   # Player 2
	]

	for player_index in range(file_paths.size()):
		var file_data = file_paths[player_index]
		var file_path = file_data["path"]
		var x_offset = file_data["x_offset"]
		var file = FileAccess.open(file_path, FileAccess.READ)

		if file:
			var displayed_units = []
			var current_unit = {}
			var weapons = false
			var rules = false
			
			while not file.eof_reached():
				var line = file.get_line().strip_edges()
				if line == "-------------------":
					if current_unit.has("Count") and current_unit["Count"] > 0:
						displayed_units.append({
							"Name": current_unit["Name"],
							"Count": current_unit["Count"],
							"Defense": current_unit["Defense"],
							"Quality": current_unit["Quality"],
							"Rules": current_unit.get("Rules", []),
							"Weapons": current_unit.get("Weapons", [])
						})
					#current_unit = {}  # Reset for the next unit
					continue
				
				var split_line = line.split(": ", false)
				if split_line.size() == 2:
					var key = split_line[0].strip_edges()
					var value = split_line[1].strip_edges()
					if key == "Count":
						current_unit[key] = int(value)
					else:
						current_unit[key] = value
				elif line == "Rules:":
					current_unit["Rules"] = []  # Initialize Rules as an empty list
					rules = true
					weapons = false 
				elif line == "Weapons:":
					current_unit["Weapons"] = []  # Initialize Weapons as an empty list
					rules = false
					weapons = true
				elif current_unit.has("Rules") and line.begins_with("-") and rules == true:
					# Append to Rules list
					current_unit["Rules"].append("- " + line.substr(1).strip_edges())
				elif current_unit.has("Weapons") and line.begins_with("-") and weapons == true:
					# Append to Weapons list
					current_unit["Weapons"].append("- " + line.substr(1).strip_edges())
			
			file.close()

			# Display units for this player
			var y_offset = 0
			for unit_data in displayed_units:
				var unit_button = Button.new()
				unit_button.text = str(unit_data["Count"]) + " x " + unit_data["Name"]
				unit_button.size = Vector2(275, 75)
				unit_button.position = Vector2(x_offset, y_offset)
				unit_button.set_meta("Name", unit_data["Name"])
				unit_button.set_meta("Count", unit_data["Count"])
				unit_button.set_meta("Player", player_index + 1)  # Store player association
				unit_button.set_meta("Defense", unit_data["Defense"])
				unit_button.set_meta("Quality", unit_data["Quality"])
				unit_button.set_meta("Rules", unit_data["Rules"])
				unit_button.set_meta("Weapons", unit_data["Weapons"])
				unit_button.set_meta("Health", 6)
				unit_button.set_meta("Movement", 12)
				unit_button.pressed.connect(func(button=unit_button): _on_unit_button_pressed(button))
				add_child(unit_button)
				player_buttons[player_index + 1].append(unit_button)  # Add to the player's list
				y_offset += 125
		else:
			print("Failed to open file: ", file_path)
	
	update_button_states()  # Ensure correct button states initially

var unit_to_place = null
var last_selected_button = null

func _on_unit_button_pressed(button: Button) -> void:
	if button.get_meta("Player") != current_player:
		return  # Ignore clicks from the inactive player
		
	# Ensure count is reduced only once per selection
	if unit_to_place == null:
		var count = button.get_meta("Count")
		if count > 0:
			unit_to_place = {
				"Name": button.get_meta("Name"),
				"Count": count,
				"Defense": button.get_meta("Defense"),  # Add these to the button
				"Quality": button.get_meta("Quality"),
				"Rules": button.get_meta("Rules"),
				"Weapons": button.get_meta("Weapons"),
				"Health": button.get_meta("Health"),
				"Movement": button.get_meta("Movement")
			}
			button.set_meta("Count", count - 1)
			button.text = str(count - 1) + " x " + button.get_meta("Name")
			last_selected_button = button

			if count - 1 == 0:
				button.disabled = true  # Disable button when out of units

	if last_selected_button != null and last_selected_button != button:
		# Restore count of the last button only if a unit was selected from it but not placed
		if unit_to_place == last_selected_button.get_meta("Name"):
			var count = last_selected_button.get_meta("Count")
			last_selected_button.set_meta("Count", count + 1)
			last_selected_button.text = str(count + 1) + " x " + last_selected_button.get_meta("Name")
			unit_to_place = null  # Reset the unit_to_place to avoid repeated increments
			
var deployment_complete = false
			
func on_unit_placed():
	if unit_to_place == null:
		return  # No unit to place

	unit_to_place = null  # Reset placement
	last_selected_button = null  # Reset selected button

	# Check if the current player has units remaining
	if !has_units_remaining(1) and !has_units_remaining(2):
		print("All units placed!")
		deployment_complete = true  # Allow movement phase
		dual_dice()
		return

	# Toggle to the other player if they have units
	current_player = 3 - current_player if has_units_remaining(3 - current_player) else current_player
	update_button_states()

func has_units_remaining(player: int) -> bool:
	for button in player_buttons[player]:
		if button.get_meta("Count") > 0:
			return true
	return false

func update_button_states():
	for player in player_buttons.keys():
		for button in player_buttons[player]:
			button.disabled = (player != current_player or button.get_meta("Count") == 0)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_position = get_global_mouse_position()
			var clicked_unit = find_unit_under_mouse(mouse_position)
			#print("Not a unit")
			
			if clicked_unit != null:
				#print("Unit")
				_on_unit_clicked(event, clicked_unit)
				get_viewport().set_input_as_handled()
				return
			
			if unit_to_place != null:
				var tile_position = local_to_map(mouse_position)
				if is_within_map(tile_position) and not is_obstacle(tile_position):
					var tile_center = map_to_local(tile_position)
					create_unit(tile_center)
					on_unit_placed()
				else:
					print("Invalid tile. Waiting for a valid click.")
			if deployment_complete:
				var clicked_tile = local_to_map(mouse_position)

				if clicked_tile in valid_tiles:
					move_unit(clicked_tile)
					
func find_unit_under_mouse(mouse_position: Vector2) -> CharacterBody2D:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_position
	query.collide_with_bodies = true  # Adjust if using areas
	query.exclude = [self]  # Exclude the map or other unrelated nodes
	
	var result = space_state.intersect_point(query)
	#print(result)
	if result.size() > 0:
		var clicked_object = result[0]["collider"]
		if clicked_object is CharacterBody2D:
			return clicked_object
	return null
			
func create_unit(position: Vector2) -> CharacterBody2D:
	var unit = CharacterBody2D.new()
	#unit.gravity_scale = 0
	unit.position = position

	# Load appropriate sprite based on the player
	var sprite = Sprite2D.new()
	if current_player == 1:
		sprite.texture = load("res://assets/Units_Red.png")
		unit.set_meta("Player", 1)
		units_player1.append(unit)
	else:
		sprite.texture = load("res://assets/Units_Blue.png")
		unit.set_meta("Player", 2)
		units_player2.append(unit)
	unit.add_child(sprite)
	
	var collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	
	# Create RectangleShape2D and set its size
	var rectangle_shape = RectangleShape2D.new()
	rectangle_shape.extents = Vector2(16, 16)  # Half of 32x32 pixels

	# Assign the RectangleShape2D to the CollisionShape2D
	collision_shape.shape = rectangle_shape
	
	unit.add_child(collision_shape)
	
	# Add tooltip as a child
	var tooltip = create_tooltip(unit_to_place)
	# Store unit data in the unit for access later
	unit.set_meta("unit_data", unit_to_place)

	# Connect click signal to handle showing tooltip
	unit.connect("input_event", Callable(self, "_on_unit_clicked").bind(unit))

	add_child(unit)
	return unit
	
func is_within_map(tile_position: Vector2i) -> bool:
	return tile_position.x >= 0 and tile_position.x < 80 and tile_position.y >= 0 and tile_position.y < 80
	
func is_obstacle(tile_position: Vector2i) -> bool:
	var atlas_coords = get_cell_atlas_coords(tile_position)
	return atlas_coords == Vector2i(4, 0)
	
func create_tooltip(unit_data: Dictionary) -> String:
	var tooltip_text = "Name: " + unit_data["Name"] + "\n"
	tooltip_text += "Defense: " + unit_data["Defense"] + "\n"
	tooltip_text += "Quality: " + unit_data["Quality"] + "\n"
		
	# Add Rules with each entry on a new line
	tooltip_text += "Rules:\n"
	for rule in unit_data["Rules"]:
		tooltip_text += rule + "\n"

	# Add Weapons with each entry on a new line
	tooltip_text += "Weapons:\n"
	for weapon in unit_data["Weapons"]:
		tooltip_text += weapon + "\n"

	# Add Health
	tooltip_text += "Health: " + str(unit_data["Health"]) + "\n"
	
	# Add Movement
	tooltip_text += "Movement: " + str(unit_data["Movement"])
	
	return tooltip_text
	
var selected_unit: CharacterBody2D = null
	
func _on_unit_clicked(event: InputEvent, unit: CharacterBody2D) -> void:
	# Handle tooltip display
	var unit_data = unit.get_meta("unit_data")
	if unit_data:
		var tooltip_text = create_tooltip(unit_data)
		$UnitInfo.clear()
		$UnitInfo.append_text(tooltip_text)
	else:
		return

	# After deployment, handle movement
	if deployment_complete:
		if selected_unit == null:
			# Select a unit
			if unit.get_meta("Player") == current_player and unit_data["Movement"] != 0:
				print("Unit selected")
				selected_unit = unit
			else:
				print("Unit has no move points left or it's not its turn")
				
		elif selected_unit == unit:
			if unit.get_meta("unit_data").Movement != 12:
				unit_data["Movement"] = 0
				unit.set_meta("unit_data", unit_data)
				check_and_handle_end_of_turn()
			# Deselect the unit
			selected_unit = null
			print("Unit deselected.")
		#else:
		#	print("You can't select another unit this turn.")

		if selected_unit:
			show_movement_options(selected_unit)


func dual_dice() -> void:
	
	var dice_player1 = randi() % 6 + 1
	var dice_player2 = randi() % 6 + 1
	$GameLog.append_text("Player 1 rolled : [color=red]" + str(dice_player1) + "[/color]\n")
	$GameLog.append_text("Player 2 rolled : [color=blue]" + str(dice_player2) + "[/color]\n")
	
	if dice_player1 > dice_player2:
		current_player = 1
		$GameLog.append_text("[color=red] Player 1 starts [/color]\n")
	elif dice_player2 > dice_player1:
		current_player = 2
		$GameLog.append_text("[color=blue] Player 2 starts [/color]\n")
	else:
		$GameLog.append_text("[color=yellow] Tie! Rolling again... [/color]\n")
		dual_dice()
	
	update_background_color()  # Aktualizacja koloru tła
		
func move_unit(target_tile: Vector2i):
	if selected_unit == null:
		return
	var unit_data = selected_unit.get_meta("unit_data")
	var movement_points = unit_data["Movement"]
	if movement_points <= 0:
		print("No movement points left!")
		return

	# Move the unit
	selected_unit.position = map_to_local(target_tile)
	selected_unit.get_node("CollisionShape2D").position = Vector2(0, 0)  # Update the parent's position
	unit_data["Movement"] = movement_points - 1
	selected_unit.set_meta("unit_data", unit_data)

	show_movement_options(selected_unit)
	
	# Check for combat opportunities
	check_for_combat(selected_unit)
	

	# End turn if movement points are exhausted
	if unit_data["Movement"] == 0:
		selected_unit = null
		check_and_handle_end_of_turn()
		
var valid_tiles = []  # To store valid movement tiles

# Check if adjacent tiles contain enemies
func check_for_combat(unit: CharacterBody2D):
	var position = local_to_map(unit.position)
	var offsets = [
		Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1),
		Vector2i(0, -1), Vector2i(0, 1),
		Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1)
	]
	
	var unit_data = unit.get_meta("unit_data")
	
	for offset in offsets:
		var adjacent_tile = position + offset
		var adjacent_unit = find_unit_at_tile(adjacent_tile)
		if adjacent_unit != null and adjacent_unit.get_meta("Player") != unit.get_meta("Player"):
			#print("Found enemy!")
			initiate_combat(unit, adjacent_unit)
			
# Find unit at a specific tile
func find_unit_at_tile(tile: Vector2i) -> CharacterBody2D:
	var tile_center = map_to_local(tile)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = tile_center
	query.collide_with_bodies = true
	
	var result = space_state.intersect_point(query)
	if result.size() > 0:
		var collider = result[0]["collider"]
		if collider is CharacterBody2D:
			return collider
	return null
		
func show_movement_options(unit: CharacterBody2D):
	valid_tiles.clear()  # Reset valid tiles
	var position = local_to_map(unit.position)
	var movement_points = unit.get_meta("Movement")

	# Get adjacent tiles (or expand for range)
	var offsets = [
		Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1),
		Vector2i(0, -1), Vector2i(0, 1),
		Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1)
	]

	for offset in offsets:
		var tile_position = position + offset
		if is_within_map(tile_position) and not is_obstacle(tile_position):
			#highlight_tile(tile_position, 0)
			valid_tiles.append(tile_position)  # Add to valid tiles


func check_and_handle_end_of_turn():
	current_player = 3 - current_player  # Switch player
	update_background_color()
	if all_units_moved(current_player):
		handle_end_of_round()
	elif current_player == 2:  # AI ma turę
		ai_controller.make_decision()  # AI podejmuje decyzje

func all_units_moved(player):
	var units = units_player1 if player == 1 else units_player2
	for unit in units:
		var unit_data = unit.get_meta("unit_data")
		if unit_data["Movement"] > 0:
			return false
	return true

func handle_end_of_round():
	if current_round >= max_rounds:
		analyze_victory_points()  # Ostateczna analiza na końcu gry
		print("Game ended!")
		return
	else:
		current_round += 1
		reset_all_units_movement()
		$GameLog.append_text("Round : [color=green]" + str(current_round) + " begins! [/color]\n")
		dual_dice()
		analyze_victory_points()  # Analiza po każdej rundzie

func reset_all_units_movement():	
	for unit in units_player1 + units_player2:
		var unit_data = unit.get_meta("unit_data")
		unit_data["Movement"] = 12  # Or default movement points
		unit.set_meta("unit_data", unit_data)
		
func _on_end_turn_pressed() -> void:
	if selected_unit == null or selected_unit.get_meta("Player") != current_player:
		return  # No unit or not the current player's unit

	var unit_data = selected_unit.get_meta("unit_data")
	unit_data["Movement"] = 0
	selected_unit.set_meta("unit_data", unit_data)
	selected_unit = null
	check_and_handle_end_of_turn()
	
func initiate_combat(attacker: CharacterBody2D, defender: CharacterBody2D):
	if attacker.get_meta("Player") == defender.get_meta("Player"):
		return  # No friendly fire!
	
	var attacker_data = attacker.get_meta("unit_data")
	var defender_data = defender.get_meta("unit_data")
	
	# Iteruj przez bronie napastnika
	for weapon in attacker_data["Weapons"]:
		if is_melee_weapon(weapon):
			var attacks = get_attack_count(weapon)
			for i in range(attacks):  # Wykonaj atak określoną liczbę razy
				$GameLog.append_text("[color=green]Attempting melee attack " + str(i + 1) + " with " + weapon + "[/color]\n")
				var attack_roll = randi() % 6 + 1
				if attack_roll > int(attacker_data["Quality"]):
					var defense_roll = randi() % 6 + 1
					$GameLog.append_text("[color=" + ("red" if current_player == 1 else "blue") + "]Attack Roll: [/color]" + str(attack_roll) + "\n")
					$GameLog.append_text("[color=" + ("blue" if current_player == 1 else "red") + "]Defense Roll: [/color]" + str(defense_roll) + "\n")
					if defense_roll < int(defender_data["Defense"]):
						apply_damage(defender)
					else:
						$GameLog.append_text("[color=yellow]The defender successfully blocked the attack![/color]\n")
				else:
					$GameLog.append_text("[color=yellow]The attack failed to break through![/color]\n")
		
# Apply damage to a unit
func apply_damage(unit: CharacterBody2D):
	var unit_data = unit.get_meta("unit_data")
	unit_data["Health"] -= 1  # Or use advanced damage calculation
	
	$GameLog.append_text("[color=orange]" + unit_data["Name"] + " took 1 damage![/color]\n")
	
	if unit_data["Health"] <= 0:
		$GameLog.append_text("[color=red]" + unit_data["Name"] + " has been defeated![/color]\n")
		remove_unit(unit)
	else:
		unit.set_meta("unit_data", unit_data)
		
# Remove a defeated unit
func remove_unit(unit: CharacterBody2D):
	if unit.get_meta("Player") == 1:
		units_player1.erase(unit)
	else:
		units_player2.erase(unit)
	unit.queue_free()
	
func is_melee_weapon(weapon: String) -> bool:
	# Sprawdzanie, czy w nawiasach występuje liczba całkowita (zasięg)
	return true  # Jeśli brak liczby w nawiasach, to broń wręcz
	
func get_attack_count(weapon: String) -> int:
	# Znajdź pierwsze wystąpienie "("
	var open_paren_index = weapon.find("(")
	if open_paren_index == -1 or open_paren_index + 2 >= weapon.length():
		return 0  # Jeśli brak nawiasu lub nie ma miejsca na "A" i cyfrę, zwróć 0

	# Sprawdź kolejne dwa znaki po nawiasie "("
	var possible_a = weapon[open_paren_index + 1]
	var possible_number = weapon[open_paren_index + 2]

	# Jeśli jest "A" i liczba od 1 do 9, zwróć tę liczbę jako int
	if possible_a == "A" and int(possible_number) in range(1, 10):
		return int(possible_number)

	# W przeciwnym razie brak liczby ataków
	return 0
