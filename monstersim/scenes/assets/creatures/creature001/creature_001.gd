extends CharacterBody2D

@export var health: float = 100
@export var hunger: float = 100
@export var stamina: float = 100
@export var energy: float = 100
@export var social: float = 100
@export var mating_need: float = 100
@export var speed = 50
@export var speed_walking = 50
@export var speed_running = 80
@export var accel = 7

@export var health_rate_modifier: float = 1.0
@export var hunger_rate_modifier: float = 0.5
@export var stamina_rate_modifier: float = 1.0
@export var energy_rate_modifier: float = 0.2
@export var social_rate_modifier: float = 0.2
@export var mating_need_rate_modifier: float = 0.2

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $"UI-Elements/Control/VBoxContainer/HealthBar"
@onready var hunger_bar: ProgressBar = $"UI-Elements/Control/VBoxContainer/HungerBar"
@onready var stamina_bar: ProgressBar = $"UI-Elements/Control/VBoxContainer/StaminaBar"
@onready var energy_bar: ProgressBar = $"UI-Elements/Control/VBoxContainer/EnergyBar"
@onready var social_bar: ProgressBar = $"UI-Elements/Control/VBoxContainer/SocialBar"
@onready var mating_need_bar: ProgressBar = $"UI-Elements/Control/VBoxContainer/MatingNeedBar"

@onready var nav = $NavigationAgent2D
@onready var nav_map = nav.get_navigation_map() # Store this once if the map doesn't change
@onready var raycast_front = $senses/vision/RayCast2DFront
@onready var collision_shape = $CollisionShape2D
@onready var search_area_hungry = $senses/areas/SearchAreaHunger
@onready var search_area_starving = $senses/areas/SearchAreaStarve

@onready var behavior_timer = $"timers/BehaviorChangeTimer"


var DELTA: float
var current_movement_target: Vector2
var movement_target_reached: bool = false
#raycast (vision) targets
var raycast_target_down_normal: Vector2 = Vector2(0,150)
var raycast_target_up_normal: Vector2 = Vector2(0,-150)
var raycast_target_left_normal: Vector2 = Vector2(-150,0)
var raycast_target_right_normal: Vector2 = Vector2(150,0)

var bar_min: float = 0
var bar_max: float = 100

var last_food_seen: StaticBody2D
# enum for behaviour based on Movement
enum MovementStates {RUNNING, STANDING, WALKING}
var movement_state: MovementStates
var current_direction: String = "down"
# enum for behaviour based on Behavior
enum BehaviorStates {EATING, FLEEING, IDLE, PLAYING, ROAMING, SEARCHING, SLEEPING, TALKING, WANDERING}
var behavior_state: BehaviorStates

enum MoodStates {ANGRY, AFRAID, ASHAMED, CONFIDENT, BORED, HAPPY, IN_LOVE, LONELY, OVERCONFIDENT, SAD, SCARED, TIRED, NOT_SET}
var mood_state_primary: MoodStates
var mood_state_first: MoodStates
var mood_state_second: MoodStates
var mood_state_third: MoodStates
var mood_state_fourth: MoodStates

enum PhysicalStates {BLEEDING, BLEEDING_BADLY, DEAD, FINE, HUNGRY, STAMINA_LOW, STARVING, WOUNDED_SMALL, WOUNDED_BADLY, NOT_SET}
var physical_state_primary: PhysicalStates
var physical_state_first: PhysicalStates
var physical_state_second: PhysicalStates
var physical_state_third: PhysicalStates
var physical_state_fourth: PhysicalStates

func _ready() -> void:
	randomize()
	TimeManager.connect("second_passed", on_timemanager_second_passed)	
	health_bar.value = health
	hunger_bar.value = hunger
	stamina_bar.value = stamina
	energy_bar.value = energy
	social_bar.value = social
	mating_need_bar.value = mating_need
	current_movement_target = global_position
	movement_state = MovementStates.STANDING
	behavior_state = BehaviorStates.IDLE
	mood_state_primary = MoodStates.HAPPY
	physical_state_primary = PhysicalStates.FINE

func _physics_process(delta: float) -> void:
	DELTA = delta
	if physical_state_primary == PhysicalStates.DEAD:
		pass
	if behavior_state == BehaviorStates.EATING:
			behavior_timer.stop()
			if hunger < bar_max:
				print("hunger < bar_max")
				hunger = hunger + 0.2
				print("hunger: ", hunger)
			if hunger >= bar_max:
				physical_state_primary = PhysicalStates.FINE
				last_food_seen.hide()
				last_food_seen = null
				behavior_timer.start()
				calculate_behavior()
				movement_target_reached = false
	elif physical_state_primary == PhysicalStates.HUNGRY || physical_state_primary == PhysicalStates.STARVING:
		if behavior_state != BehaviorStates.EATING:
			behavior_state = BehaviorStates.SEARCHING
		# if npc remembers noticing food somewhere
		if last_food_seen && movement_target_reached == false:
			move_towards_target(last_food_seen)
		if last_food_seen && movement_target_reached == true:
			print("SETTING BEHAVIOR TO EATING")
			behavior_state = BehaviorStates.EATING
		else:
			pass
			
		
			
		
		if physical_state_primary == PhysicalStates.HUNGRY:
			#print("HUNGRY")
			search_area_starving.hide()
			search_area_hungry.show()
		
		if physical_state_primary == PhysicalStates.STARVING:
			#print("STARVING")
			search_area_starving.show()
			search_area_hungry.hide()
		
		behavior_timer.stop()
		
	else:
		search_area_hungry.hide()
		search_area_starving.hide()

	if behavior_timer.is_stopped() == true && behavior_state != BehaviorStates.EATING:
		calculate_behavior_basics()
		behavior_timer.wait_time = randf_range(2.0, 6.0) if behavior_state == BehaviorStates.SEARCHING else randf_range(6.0, 10.0)
		behavior_timer.start()

	if behavior_state != BehaviorStates.EATING && behavior_state != BehaviorStates.IDLE && behavior_state != BehaviorStates.PLAYING && behavior_state != BehaviorStates.SLEEPING &&behavior_state != BehaviorStates.TALKING:
		var direction = Vector2()
		#########
		if nav.is_navigation_finished():
			return

		# Move towards the next path point
		direction = nav.get_next_path_position() - global_position
		direction = direction.normalized()

		velocity = velocity.lerp(direction * speed, accel * delta)

		if nav.avoidance_enabled:
			nav.set_velocity(velocity)
		else:
			_on_navigation_agent_2d_velocity_computed(velocity)

		move_and_slide()
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_collider().is_in_group("npcs"):
				print("Collided with another NPC: ", collision.get_collider())
		
		current_direction = get_cardinal_direction(direction)
	var states = BehaviorStates.keys()
	
	#########
	anim.play("idle_down")
	#wander_randomly()
	calculate_physicalstate()
	calculate_mood()
	set_vision_raycast(current_direction)
	set_bars()
	
func search_food():
	pass
	
	
func move_towards_target(target: Node2D)->void:
	if movement_target_reached == true:
		return
	var targetPos: Vector2 = target.global_position
	var direction = Vector2()
	#print(targetPos)
	nav.target_position = targetPos
	#print("Target: %s"%targetPos)
	#print("Me: %s"%global_position)
	direction = nav.get_next_path_position() - global_position
	direction = direction.normalized()
	#print(direction)
	
	velocity = velocity.lerp(direction * speed, accel * DELTA)
	
	if nav.avoidance_enabled:
		nav.set_velocity(velocity)
	else:
		_on_navigation_agent_2d_velocity_computed(velocity)
	move_and_slide()
	# Get the dominant cardinal direction
	current_direction = get_cardinal_direction(direction)
	var distance_to_target = global_position.distance_to(targetPos)
	print("distance: ", distance_to_target)
	if distance_to_target < 10:
		movement_target_reached = true
	#print("Moving: ", current_direction)

func wander_randomly(min_distance := 50, max_distance := 200, max_attempts := 10):
	var direction = Vector2()
	for i in range(max_attempts):
		var angle = randf() * TAU # TAU = 2*PI
		var distance = randf_range(min_distance, max_distance)
		var offset = Vector2(cos(angle), sin(angle)) * distance
		var candidate_position = global_position + offset

		# Check if the position is reachable (i.e., on the navmesh)
		var targetPos = NavigationServer2D.map_get_closest_point(nav_map, candidate_position)
		
		# Optionally, add a check: is it close enough to the original?
		if global_position.distance_to(targetPos) <= distance * 1.5:
			nav.target_position = targetPos
			#print("Wandering to: ", targetPos)
			direction = nav.get_next_path_position() - global_position
			direction = direction.normalized()
			#print("DIR: ",direction)
			return true # success

	print("Couldn't find valid wander target")
	return false # fallback if no valid point found
	behavior_state = BehaviorStates.IDLE

func get_cardinal_direction(direction: Vector2) -> String:
	if abs(direction.x) > abs(direction.y):
		return "right" if direction.x > 0 else "left"
	else:
		return "down" if direction.y > 0 else "up"
		
func set_vision_raycast(facing: String)->void:
	if facing == "down":
		raycast_front.target_position = raycast_target_down_normal
	if facing == "up":
		raycast_front.target_position = raycast_target_up_normal
	if facing == "left":
		raycast_front.target_position = raycast_target_left_normal
	if facing == "right":
		raycast_front.target_position = raycast_target_right_normal
	#print(raycast_front.target_position)
	#print("current_dir in set_vision_raycast", facing)

func calculate_behavior_basics()->void:
	calculate_behavior()
	calculate_movement()

func calculate_mood()->int:
	return mood_state_primary

func calculate_physicalstate()->int:
	# unset physical states so they can be set or ignored if not set already
	physical_state_primary = PhysicalStates.NOT_SET
	physical_state_first = PhysicalStates.NOT_SET
	physical_state_second = PhysicalStates.NOT_SET
	physical_state_third = PhysicalStates.NOT_SET
	physical_state_fourth = PhysicalStates.NOT_SET
	
	# var physicalStates = { "first": null, "second": null, "tird": null, "fourth": null}
	# checkIfPhysicalStatesSetInObject(physicalStates)
	# first look if npc is still alive
	if health <= 0:
		physical_state_primary = PhysicalStates.DEAD
		return physical_state_primary
	# do hunger now because its a critical value
	if hunger < 55:
		# if hunger not critical, put it on a "normal" state
		physical_state_primary = PhysicalStates.HUNGRY
		if hunger < 15:
			# hunger is critical, so it needs to be priority
			physical_state_primary = PhysicalStates.STARVING
			# return this state so npc can search and find food or else will die
	return physical_state_primary

func checkIfPhysicalStatesSetInObject(physicalStates)->String:
	var keys = physicalStates.keys()
	#print(keys)
	#for state in physicalStates:
		#print(physicalStates[state])
	return "null"

func calculate_behavior()->int:
	var new_behavior = behavior_state
	
	while new_behavior == behavior_state || behavior_state == BehaviorStates.EATING:
		#print("BehaviorState: ", behavior_state)
		var enum_values = BehaviorStates.values()
		behavior_state = enum_values[randi() % enum_values.size()]
		#print("BehaviorState: ", behavior_state)
	if physical_state_primary == PhysicalStates.HUNGRY || physical_state_primary == PhysicalStates.STARVING:
		behavior_state = BehaviorStates.SEARCHING
	return behavior_state

func calculate_movement()->void:
	var enum_values = MovementStates.values()
	movement_state = enum_values[randi() % enum_values.size()]
	if movement_state == MovementStates.RUNNING:
		speed = speed_running
	if movement_state == MovementStates.WALKING:
		speed = speed_walking
	if movement_state == MovementStates.STANDING && behavior_state != BehaviorStates.EATING:
		behavior_state = BehaviorStates.IDLE

func set_bars() -> void:
	health_bar.value = health
	hunger_bar.value = hunger
	stamina_bar.value = stamina
	energy_bar.value = energy
	social_bar.value = social
	mating_need_bar.value = mating_need


func set_current_food_target(new_food: Node2D):
	if last_food_seen:
		var position_old = last_food_seen.global_position
		var position_new = new_food.global_position
		if global_position.distance_to(position_new) < global_position.distance_to(position_old):
			last_food_seen = new_food
	else:
		last_food_seen = new_food

func on_timemanager_second_passed() -> void:
	#print(movement_state)
	if behavior_state != BehaviorStates.EATING:
		hunger = hunger - (1 * hunger_rate_modifier)
		if hunger < bar_min:
			hunger = bar_min
	energy = energy - (1 * energy_rate_modifier)
	social = social - (1 * social_rate_modifier)
	mating_need = mating_need - (1 * mating_need_rate_modifier)
	
	if health < bar_min:
		health = bar_min
	if stamina < bar_min:
		stamina = bar_min
	if energy < bar_min:
		energy = bar_min
	if social < bar_min:
		social = bar_min
	if mating_need < bar_min:
		mating_need = bar_min

func _on_behavior_change_timer_timeout() -> void:
	if !nav.is_navigation_finished():
		return # Already going somewhere
	
	# CHECK FOR CONDITIONS OF NPC AND ADD MORE BEHAVIORs
	#	 if needs social interactions, do something
	#	 if has hunger, do something else
	#	 and so on...
	
	# Default:
	wander_randomly()


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity

func _on_search_area_hunger_body_entered(body: Node2D) -> void:
	if physical_state_primary == PhysicalStates.HUNGRY:
		if body.is_in_group("apple"):
			set_current_food_target(body)

func _on_search_area_starve_body_entered(body: Node2D) -> void:
	if physical_state_primary == PhysicalStates.STARVING:
		if body.is_in_group("apple"):
			set_current_food_target(body)

func _on_default_noticing_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("apple"):
		set_current_food_target(body)
