extends StaticBody2D

var is_spawned: bool = true
var is_being_eaten: bool = false

func _ready() -> void:
	FoodManager.set_food(self, true)
