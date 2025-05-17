# AIController.gd
class_name AIController
extends Node

var units = []  # Lista jednostek AI
var victory_points = []  # Lista punktów zwycięstwa
var game_layer = null  # Referencja do głównego TileMapLayer
var current_phase = "early"  # Aktualna faza gry: "early", "win", "lose"

func _init(game_ref: Node):
	game_layer = game_ref  # Przekazanie głównego skryptu gry

# Wywoływane w turze AI
func make_decision():
	# Aktualizuj fazę gry
	print("update phase")
	update_phase()
	
	# Wykonaj decyzje w zależności od fazy gry
	if current_phase == "early":
		pursue_neutral_points()
	elif current_phase == "win":
		defend_victory()
	elif current_phase == "lose":
		regain_control()

# Aktualizacja fazy gry na podstawie punktów
func update_phase():
	var ai_score = count_ai_victory_points()
	var player_score = count_player_victory_points()
	if ai_score > player_score:
		current_phase = "win"
	elif ai_score < player_score:
		current_phase = "lose"
	else:
		current_phase = "early"
	print(current_phase)

func count_ai_victory_points() -> int:
	var points = 0
	for point in victory_points:
		if game_layer.point_status.get(point) == "player2":
			points += 1
	return points

func count_player_victory_points() -> int:
	var points = 0
	for point in victory_points:
		if game_layer.point_status.get(point) == "player1":
			points += 1
	return points

func pursue_neutral_points():
	print("pursue neutral")
	for unit in units:
		var target_point = find_closest_neutral_point(unit)
		if target_point:
			move_to_target(unit, target_point)

# Znajdź najbliższy neutralny punkt
func find_closest_neutral_point(unit) -> Vector2i:
	var closest_point = null
	var shortest_distance = INF
	for point in victory_points:
		if game_layer.point_status.get(point) == "neutral":
			var distance = calculate_distance(unit.position, point)
			if distance < shortest_distance:
				closest_point = point
				shortest_distance = distance
	print(closest_point)
	return closest_point

# Ruch jednostki do celu
func move_to_target(unit, target_point):
	var path = calculate_path(unit, target_point)
	if path.size() > 0:
		game_layer.move_unit(path[0])  # Wykorzystaj istniejącą funkcję ruchu
		
func defend_victory():
	for unit in units:
		if is_near_contested_point(unit):
			attack_nearest_enemy(unit)
		else:
			move_to_support(unit)

func regain_control():
	for unit in units:
		if is_near_contested_point(unit):
			attack_nearest_enemy(unit)
		else:
			move_to_neutral_or_enemy_point(unit)
			
func attack_nearest_enemy(unit):
	var enemies = find_adjacent_enemies(unit)
	var target = prioritize_targets(enemies)
	if target:
		game_layer.initiate_combat(unit, target)

func prioritize_targets(enemies):
	var best_target = null
	var best_score = -INF
	for enemy in enemies:
		var enemy_data = enemy.get_meta("unit_data")
		var score = calculate_target_score(enemy_data)
		if score > best_score:
			best_score = score
			best_target = enemy
	return best_target

func calculate_target_score(enemy_data):
	return enemy_data["Defense"] * -1 + (6 - enemy_data["Health"]) * 2  # Im mniej HP, tym wyższy priorytet
	
func calculate_distance(pos1: Vector2, pos2: Vector2) -> int:
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)
	
func calculate_path(unit, target_point) -> Array:
	var start = game_layer.local_to_map(unit.position)
	var end = target_point
	return game_layer.get_simple_path(start, end, false)  # Algorytm A*
	
func is_near_contested_point(unit) -> bool:
	for point in victory_points:
		if game_layer.point_status.get(point) == "contested":
			var distance = calculate_distance(unit.position, point)
			if distance <= 3:
				return true
	return false
	
func move_to_support(unit):
	var closest_point = null
	var shortest_distance = INF
	for point in victory_points:
		if game_layer.point_status.get(point) == "player2":  # Punkt zajęty przez AI
			var distance = calculate_distance(unit.position, point)
			if distance < shortest_distance:
				closest_point = point
				shortest_distance = distance
	if closest_point:
		move_to_target(unit, closest_point)
		
func move_to_neutral_or_enemy_point(unit):
	var closest_point = null
	var shortest_distance = INF
	for point in victory_points:
		if game_layer.point_status.get(point) in ["neutral", "player1"]:
			var distance = calculate_distance(unit.position, point)
			if distance < shortest_distance:
				closest_point = point
				shortest_distance = distance
	if closest_point:
		move_to_target(unit, closest_point)
		
func find_adjacent_enemies(unit) -> Array:
	var adjacent_enemies = []
	var unit_position = game_layer.local_to_map(unit.position)
	var offsets = [
		Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)
	]
	for offset in offsets:
		var neighbor = unit_position + offset
		var enemy = game_layer.find_unit_at_tile(neighbor)
		if enemy and enemy.get_meta("Player") != unit.get_meta("Player"):
			adjacent_enemies.append(enemy)
	return adjacent_enemies
	

	
