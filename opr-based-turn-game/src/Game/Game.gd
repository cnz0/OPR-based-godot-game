extends Camera2D

var zoom_step := 0.1
var min_zoom := 0.5
var max_zoom := 2.0
var rotation_speed := 100

var is_paused = false
var shade_rectangle

func _ready():
	set_process_input(true)
	shade_rectangle = get_parent().get_node("ColorRect")

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_ESCAPE:  # ESC key (map in Input Map)
				toggle_pause()
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		#	zoom *= (1 - zoom_step)
		#	zoom = clamp(zoom, Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
		#elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
		#	zoom *= (1 + zoom_step)
		#	zoom = clamp(zoom, Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
			
	# Move camera with left mouse button held down

		
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_SPACE:
				rotation_degrees = 0
				

func _process(delta):
	if Input.is_action_pressed("rotate_left"):  # Ensure to set "rotate_left" in Input Map for 'Q'
		rotation_degrees -= rotation_speed * delta
	elif Input.is_action_pressed("rotate_right"):  # Ensure to set "rotate_right" in Input Map for 'E'
		rotation_degrees += rotation_speed * delta
		
	var move_speed = 500 * delta / zoom.x  # Adjust for delta and zoom

	if Input.is_action_pressed("move_up"):
		position.y -= move_speed
	if Input.is_action_pressed("move_down"):
		position.y += move_speed
	if Input.is_action_pressed("move_left"):
		position.x -= move_speed
	if Input.is_action_pressed("move_right"):
		position.x += move_speed
	
	# Clamp the position to stay within the fixed boundaries
	position.x = clamp(position.x, 0, 2560)
	position.y = clamp(position.y, 0, 2560)
		
func toggle_pause():
	if !is_paused:
		shade_rectangle.modulate.a = 0.6
		shade_rectangle.position = self.global_position
	else:
		shade_rectangle.modulate.a = 0.0
	is_paused = !is_paused
	$PauseMenu.visible = is_paused
	
func _on_resume_game_button_pressed() -> void:
	toggle_pause()


func _on_quit_game_button_pressed() -> void:
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://src/Menu/MainMenu.tscn")
