extends Node2D

@onready var seconds_timer = $SecondsTimer
@onready var minutes_timer = $MinutesTimer

var time_is_paused: bool = false
var game_seconds: int = 0 
var game_minutes: int = 0 

signal second_passed
signal minute_passed

func start_timers() -> void:
	seconds_timer.paused = false
	minutes_timer.paused = false
	time_is_paused = false

func stop_timers() -> void:
	seconds_timer.paused = true
	minutes_timer.paused = true
	time_is_paused = true

func _on_seconds_timer_timeout() -> void:
	if time_is_paused == false:
		print("seconds: ",game_seconds)
		game_seconds+=1
		emit_signal("second_passed")


func _on_minutes_timer_timeout() -> void:
	if time_is_paused == false:
		game_minutes+=1
		print("minutes: ",game_minutes)
		emit_signal("minute_passed")
