extends Control

var armies = []
var army_inited = false

var game_mode


func _ready():
	$ColorRect.modulate.a = 0
	var dir = DirAccess.open("res://config/")
	if dir:
		for file_name in dir.get_files():
				armies.append(file_name.trim_suffix(".txt"))
	else:
		print("Failed to open directory: res://config/")


func _on_play_button_pressed() -> void:
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://src//Menu/PickGamemode.tscn")
	
	
func _on_options_button_pressed() -> void:
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://src/Menu/Options.tscn")


func _on_quit_button_pressed() -> void:
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().quit()


func _on_singleplayer_pressed() -> void:
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://src/Menu/SinglePlayerChooseMode.tscn")


func _on_multiplayer_pressed() -> void:
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://src/Menu/MultiPlayerChooseMode.tscn")


func _on_back_pressed() -> void:
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://src//Menu/MainMenu.tscn")


func _on_gamemode_back_pressed() -> void:
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://src/Menu/PickGamemode.tscn")
	

func _on_army_builder_back_pressed() -> void:
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://src/Menu/PickGamemode.tscn")
	

func _on_hotseat_mode_pressed() -> void:
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://src/Menu/ArmyBuilderMenu.tscn")
	Global.game_mode = "PvP"
	
func _on_ai_mode_pressed() -> void:
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://src/Menu/ArmyBuilderMenu.tscn")
	Global.game_mode = "PvAI"


func _on_players_pressed() -> void:
	$PlayerConfig.visible = true
	

func _on_armies_pressed() -> void:
	$ArmyBuilder.visible = true
	#$ArmyBuilder/ArmyMenu.visible = false
	if army_inited == false:
		_set_armies_init()
	

func _on_player_config_confirm_pressed() -> void:
	$PlayerConfig.visible = false


func _on_start_game_pressed() -> void:
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://src/Game/Map.tscn")
	

func _set_armies_init() -> void:
	var dropdown_first = $ArmyBuilder/BuildArmyOne
	var dropdown_second = $ArmyBuilder/BuildArmyTwo
	
	dropdown_first.clear()
	dropdown_second.clear()
	
	for army in armies:
		dropdown_first.add_item(army)
		dropdown_second.add_item(army)
	army_inited = true


func _on_choose_player_back_pressed() -> void:
	$Armies/PickPlayer.visible = false
	
func get_game_mode() -> String:
	return game_mode
