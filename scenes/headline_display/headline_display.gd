extends Control

signal headline_vote_started(headline: Headline)
signal headline_vote_stopped(headline: Headline)

@export var headlines: HeadlineContainer = preload("res://assets/resources/headlines.tres")

var current_headline: Headline

func _ready() -> void:
	display_new_headline()


func _process(_delta: float) -> void:
	$VBoxContainer/TextureProgressBar.value = $Timer.time_left / $Timer.wait_time * 100


func display_new_headline() -> void:
	if current_headline:
		headline_vote_stopped.emit(current_headline)
	current_headline = headlines.headlines.pick_random()
	headline_vote_started.emit(current_headline)
	$VBoxContainer/Label.text = current_headline.text
	

func _on_timer_timeout() -> void:
	display_new_headline()
