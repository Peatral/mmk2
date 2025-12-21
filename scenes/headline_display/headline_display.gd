extends Control

@export var headlines: HeadlineContainer = preload("res://assets/resources/headlines.tres")

var current_headline: Headline

func _ready() -> void:
	display_new_headline()


func _process(delta: float) -> void:
	$VBoxContainer/TextureProgressBar.value = $Timer.time_left / $Timer.wait_time * 100


func display_new_headline() -> void:
	current_headline = headlines.headlines.pick_random()
	$VBoxContainer/Label.text = current_headline.text
	

func _on_timer_timeout() -> void:
	display_new_headline()
