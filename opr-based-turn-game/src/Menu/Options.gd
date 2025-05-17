extends Control

var resolutions = [
	Vector2(800, 600),
	Vector2(1280, 720),
	Vector2(1920, 1080)
]

func _ready():
	$ColorRect.modulate.a = 0

func _on_back_pressed() -> void:
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://src//Menu/MainMenu.tscn")
	
func _on_confirm_pressed() -> void:
	pass # Replace with function body.

func _on_resolution_slider_value_changed(value: float) -> void:
	var index = int(value)
	if index >= 0 and index < resolutions.size():
		var new_resolution = resolutions[index]
		DisplayServer.window_set_size(new_resolution)
