extends Node

var is_initialized = {1: false, 2: false}
var selected_army_1 = ""
var selected_army_2 = ""
var player_one_name = ""
var player_two_name = ""
var player_unit_counts = {}
var player_existing_unit_data = {}
var player_initialized_items = {}
var player_one_selected = false
var player_two_selected = false


func _player_one_set_army_pressed(index: int) -> void:
	selected_army_1 = $BuildArmyOne.get_item_text(index)
	$EditArmy.disabled = false
	player_one_selected = true
	player_two_selected = false
		
		
func _player_two_set_army_pressed(index: int) -> void:
	selected_army_2 = $BuildArmyTwo.get_item_text(index)
	$EditArmy2.disabled = false
	player_one_selected = false
	player_two_selected = true


func _on_edit_army_pressed() -> void:
	$ArmyMenu.visible = true
	# Clear previously initialized items to avoid referencing freed objects
	player_initialized_items.clear()
	player_unit_counts.clear()
	player_existing_unit_data.clear()
	# Rebuild the UI with the new army
	build_unit_labels("res://config/" + selected_army_1 + ".txt", $ArmyMenu)
	$BuildArmyOne.disabled = true
	$BuildArmyTwo.disabled = true
	
	
func _on_edit_army_2_pressed() -> void:
	$ArmyMenu2.visible = true
	# Clear previously initialized items to avoid referencing freed objects
	player_initialized_items.clear()
	player_unit_counts.clear()
	player_existing_unit_data.clear()
	# Rebuild the UI with the new army
	build_unit_labels("res://config/" + selected_army_2 + ".txt", $ArmyMenu2)
	$BuildArmyOne.disabled = true
	$BuildArmyTwo.disabled = true
	
	
func _on_line_edit_text_submitted(name: String) -> void:
	if name.strip_edges() == "":
		return
	player_one_name = name
	get_node("../PlayerConfig/LineEdit").editable = false
	

func _on_line_edit_2_text_submitted(name: String) -> void:
	if name.strip_edges() == "":
		return
	player_two_name = name
	get_node("../PlayerConfig/LineEdit2").editable = false
	
	
func build_unit_labels(file_path: String, color_rect: ColorRect) -> void:
	# Clear existing children
	for child in color_rect.get_children():
		if child is ItemList or (child is Label and child.text.begins_with("Total Cost:")):
			color_rect.remove_child(child)
			child.queue_free()
	player_initialized_items.clear()
	
	# Read the file and extract unit data
	var unit_data_list = []  # Store all unit data
	var file = FileAccess.open(file_path, FileAccess.READ)
	print(file_path)
	if file:
		var is_unit_section = false
		while not file.eof_reached():
			var line = file.get_line()
			if line.strip_edges() == "Units:":
				is_unit_section = true
				continue
			elif line.strip_edges() == "Upgrades:" or line.strip_edges() == "":
				is_unit_section = false
			
			if is_unit_section:
				var json = JSON.new()
				var parse_error = json.parse(line.strip_edges())
				if parse_error != OK:
					print("Error parsing JSON: ", parse_error)
					continue
				
				var unit_data = json.get_data()
				if "name" in unit_data and "cost" in unit_data:
					unit_data_list.append(unit_data)
		file.close()
	
	# Create ItemList for units
	var item_list = ItemList.new()
	item_list.custom_minimum_size = Vector2(550, 300)
	item_list.position = Vector2(50, 50)
	color_rect.add_child(item_list)  # Add ItemList to ColorRect

	# Populate ItemList
	for unit_data in unit_data_list:
		var item_text = unit_data["name"] + " (Cost: " + str(unit_data["cost"]) + ")"
		var item_index = item_list.add_item(item_text)
		player_unit_counts[item_index] = {"count": 0, "cost": unit_data["cost"]}  # Store the full unit data for each item
		player_existing_unit_data[item_index] = unit_data

	# Create a ScrollContainer for displaying unit details
	var details_container = ScrollContainer.new()
	details_container.custom_minimum_size = Vector2(550, 300)
	details_container.position = Vector2(650, 50)
	#details_container.modulate = Color(1, 1, 1, 1)  # Alpha value of 0.5 (128/255)
	#details_container.scroll_vertical_enabled = true
	color_rect.add_child(details_container)
	
	for child in color_rect.get_children():
		if child is ScrollContainer:
			for grandchild in child.get_children():
				if grandchild is Label:
					grandchild.text = ""  # Clear the details text

	var details_label = Label.new()
	#details_label.autowrap = true
	details_container.add_child(details_label)
	
	# Remove any existing Total Cost Label
	for child in color_rect.get_children():
		if child is Label and child.text.begins_with("Total Cost:"):
			color_rect.remove_child(child)
			child.queue_free()
	
	# Label to display total cost
	var total_cost_label = Label.new()
	total_cost_label.text = "Total Cost: 0"
	total_cost_label.custom_minimum_size = Vector2(550, 50)
	total_cost_label.position = Vector2(50, 400)
	color_rect.add_child(total_cost_label)

	# Connect item_selected signal
	item_list.item_selected.connect(func(selected_index: int) -> void:
		_on_item_selected(selected_index, item_list, details_label, total_cost_label)
	)

func _on_item_selected(selected_index: int, item_list: ItemList, details_label: Label, total_cost_label: Label) -> void:
	# Hide all previously initialized button boxes
	for key in player_initialized_items.keys():
		player_initialized_items[key].visible = false
		
		# Check if the selected item already has its buttons/labels created
	if player_initialized_items.has(selected_index):
		print("Buttons already initialized for item ", selected_index)
		# Make the existing button box visible
		player_initialized_items[selected_index].visible = true
	else:
		print("Initializing buttons for: ", item_list.get_item_text(selected_index))

		# Create button box for this item
		var button_box = BoxContainer.new()
		button_box.custom_minimum_size = Vector2(550, 50)
		button_box.position = Vector2(350,225)

		# Counter Label
		var counter_label = Label.new()
		counter_label.text = str(player_unit_counts[selected_index]["count"])  # Get initial count
		counter_label.custom_minimum_size = Vector2(50, 50)
		button_box.add_child(counter_label)

		# "+" Button
		var increase_button = Button.new()
		increase_button.text = "+"
		increase_button.custom_minimum_size = Vector2(50, 50)
		button_box.add_child(increase_button)

		# "-" Button
		var decrease_button = Button.new()
		decrease_button.text = "-"
		decrease_button.custom_minimum_size = Vector2(50, 50)
		button_box.add_child(decrease_button)

		# Update count and total cost on button press
		increase_button.pressed.connect(func():
			player_unit_counts[selected_index]["count"] += 1
			counter_label.text = str(player_unit_counts[selected_index]["count"])
			_update_total_cost(total_cost_label)
		)

		decrease_button.pressed.connect(func():
			if player_unit_counts[selected_index]["count"] > 0:
				player_unit_counts[selected_index]["count"] -= 1
				counter_label.text = str(player_unit_counts[selected_index]["count"])
				_update_total_cost(total_cost_label)
		)

		# Add button box below the ItemList
		item_list.add_child(button_box)

		# Mark this item as initialized and show it
		player_initialized_items[selected_index] = button_box

	# Make the button box visible
	player_initialized_items[selected_index].visible = true
		
	# Fetch selected unit data
	var selected_unit = player_existing_unit_data[selected_index]
	
	# Extract unit stats
	var unit_name = selected_unit["name"]
	var unit_cost = selected_unit["cost"]
	var unit_defense = selected_unit["defense"]
	var unit_quality = selected_unit["quality"]
	
	# Extract rules
	var unit_rules = selected_unit.get("rules", [])
	var rules_text = "Rules:\n"
	for rule in unit_rules:
		rules_text += "- " + rule["label"] + "\n"

	# Extract weapons
	var unit_weapons = selected_unit.get("weapons", [])
	var weapons_text = "Weapons:\n"
	for weapon in unit_weapons:
		weapons_text += "- " + weapon["label"] + "\n"

	# Combine details into a formatted string
	var details_text = "Name: " + unit_name + "\n"
	details_text += "Cost: " + str(unit_cost) + "\n"
	details_text += "Defense: " + str(unit_defense) + "\n"
	details_text += "Quality: " + str(unit_quality) + "\n\n"
	details_text += rules_text + "\n" + weapons_text

	# Update the details label with the new text
	details_label.text = details_text

func _update_total_cost(total_cost_label: Label) -> void:
	var total_cost = 0
	for unit in player_unit_counts.values():
		total_cost += unit["count"] * unit["cost"]
	total_cost_label.text = "Total Cost: " + str(total_cost)
		
		
func _on_army_builder_confirm_pressed() -> void:
	self.visible = false
	

func _on_army_menu_confirm_pressed() -> void:
	$ArmyMenu.visible = false
	$ArmyMenu2.visible = false
	$BuildArmyOne.disabled = false
	$BuildArmyTwo.disabled = false
	save_armies_to_temp_file()

func save_armies_to_temp_file() -> void:
	var temp_file_path
	if player_one_selected:
		temp_file_path = "res://temp/armies_hotseat_temp_one.txt"
	if player_two_selected:
		temp_file_path = "res://temp/armies_hotseat_temp_two.txt"
	var temp_file = FileAccess.open(temp_file_path, FileAccess.WRITE)
	if temp_file:
		for index in player_unit_counts.keys():
			var unit_data = player_existing_unit_data[index]
			var unit_count = player_unit_counts[index]["count"]
			var details_text = build_details_text(unit_data)
			
			# Save unit details to the file
			temp_file.store_line("Unit Name: " + unit_data["name"])
			temp_file.store_line("Count: " + str(unit_count))
			temp_file.store_line(details_text)
			temp_file.store_line("-------------------")  # Separator for readability

		temp_file.close()
		print("Army data saved to temporary file:", temp_file_path)
	else:
		print("Error: Unable to open temporary file for writing.")
		
func build_details_text(unit_data: Dictionary) -> String:
	# Generate the details_text string based on unit_data
	var details_text = "Name: " + unit_data["name"] + "\n"
	details_text += "Cost: " + str(unit_data["cost"]) + "\n"
	details_text += "Defense: " + str(unit_data["defense"]) + "\n"
	details_text += "Quality: " + str(unit_data["quality"]) + "\n"
	
	var rules_text = "Rules:\n"
	for rule in unit_data.get("rules", []):
		rules_text += "- " + rule["label"] + "\n"
	
	var weapons_text = "Weapons:\n"
	for weapon in unit_data.get("weapons", []):
		weapons_text += "- " + weapon["label"] + "\n"
	
	details_text += rules_text + "\n" + weapons_text
	return details_text
