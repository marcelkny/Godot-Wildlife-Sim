extends Camera2D

@export var move_speed_min := 200             # Target speed of camera movement
@export var move_speed_max := 700
var move_speed := 500
@export var easing := 0.1                    # How quickly the camera catches up (0.0 - 1.0)
@export var zoom_speed := 0.15
@export var min_zoom := 0.5
@export var max_zoom := 4.0

var target_position: Vector2

func _ready():
	target_position = global_position
	
func _process(delta):
	var input_vector := Vector2.ZERO

	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1

	# Calculate target position based on input
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		target_position += input_vector * move_speed * delta

	# Smoothly move the camera toward the target position
	global_position = global_position.lerp(target_position, easing)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(zoom_speed)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			zoom_camera(zoom_speed)
		elif event.keycode == KEY_E:
			zoom_camera(-zoom_speed)

func zoom_camera(amount):
	var new_zoom = zoom + Vector2(amount, amount)
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)		
	move_speed = move_speed / new_zoom.x
	if move_speed < move_speed_min:
		move_speed = move_speed_min
	if move_speed > move_speed_max:
		move_speed = move_speed_max
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	zoom = new_zoom
