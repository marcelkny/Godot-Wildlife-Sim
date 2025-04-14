extends CharacterBody2D

@export var health: float = 100
@export var hunger: float = 100
@export var stamina: float = 100
@export var energy: float = 100
@export var social: float = 100
@export var mating_need: float = 100

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

var bar_min: float = 0
var bar_max: float = 100

# enum for behaviour based on Movement
enum MovementStates {RUNNING, STANDING, WALKING}
var movement_state: MovementStates

# enum for behaviour based on Behavior
enum BehaviorStates {EATING, FLEEING, IDLE, PLAYING, ROAMING, SEARCHING, SLEEPING, TALKING}
var behavior_state: BehaviorStates

enum MoodStates {ANGRY, AFRAID, ASHAMED, CONFIDENT, BORED, HAPPY, IN_LOVE, LONELY, SAD, SCARED, TIRED, NOT_SET}
var mood_state_primary: MoodStates
var mood_state_first: MoodStates
var mood_state_second: MoodStates
var mood_state_third: MoodStates
var mood_state_fourth: MoodStates

enum PhysicalStates {BLEEDING, BLEEDING_BADLY, DEAD, FINE, STAMINA_LOW, STARVING, WOUNDED_SMALL, WOUNDED_BADLY, NOT_SET}
var physical_state_primary: PhysicalStates
var physical_state_first: PhysicalStates
var physical_state_second: PhysicalStates
var physical_state_third: PhysicalStates
var physical_state_fourth: PhysicalStates

func _ready() -> void:
	TimeManager.connect("second_passed", on_second_passed)	
	health_bar.value = health
	hunger_bar.value = hunger
	stamina_bar.value = stamina
	energy_bar.value = energy
	social_bar.value = social
	mating_need_bar.value = mating_need
	
	movement_state = MovementStates.STANDING
	behavior_state = BehaviorStates.ROAMING
	mood_state_first = MoodStates.HAPPY
	physical_state_primary = PhysicalStates.FINE

func _physics_process(delta: float) -> void:
	anim.play("idle")
	set_bars()


func calculate_mood()->void:
	pass

func calculate_physicalstate()->void:
	pass

func calculate_behavior()->void:
	pass

func calculate_movement()->void:
	pass

func set_bars() -> void:
	health_bar.value = health
	hunger_bar.value = hunger
	stamina_bar.value = stamina
	energy_bar.value = energy
	social_bar.value = social
	mating_need_bar.value = mating_need

func on_second_passed() -> void:
	print(movement_state)
	hunger = hunger - (1 * hunger_rate_modifier)
	energy = energy - (1 * energy_rate_modifier)
	social = social - (1 * social_rate_modifier)
	mating_need = mating_need - (1 * mating_need_rate_modifier)
	
	if health < bar_min:
		health = bar_min
	if hunger < bar_min:
		hunger = bar_min
	if stamina < bar_min:
		stamina = bar_min
	if energy < bar_min:
		energy = bar_min
	if social < bar_min:
		social = bar_min
	if mating_need < bar_min:
		mating_need = bar_min
