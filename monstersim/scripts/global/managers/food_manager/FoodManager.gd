extends Node

var apple_dict: Dictionary = {"[Object]": {"global_position": Vector2(0,0), "is_available": false}}

func _ready() -> void:
	apple_dict.erase("[Object]")
	
func _physics_process(delta: float) -> void:
	#apple_dict.erase("[Object]")
	pass
	
func set_food(object: StaticBody2D, is_available: bool)->void:
	if object == null:
		return
	apple_dict[object] = {"global_position": object.global_position, "is_available": is_available}

func is_food_available(food: StaticBody2D)->bool:
	if apple_dict.has(food):
		var food_item = apple_dict[food]
		return food_item["is_available"]
	return false
