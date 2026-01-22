extends Control

signal headline_vote_started(headline: Headline)
signal headline_vote_stopped(headline: Headline)

@export var headlines: HeadlineContainer = preload("res://assets/resources/headlines.tres")

var current_headline: Headline

var round = 0

func _ready() -> void:
	display_new_headline()


func _process(_delta: float) -> void:
	$ProgressBar.value = ($Timer.wait_time - $Timer.time_left) / $Timer.wait_time * 100


func display_new_headline() -> void:
	round += 1
	$ProgressBar.value = 0
	$ProgressBar.visible = true
	$Timer.start()
	if round >= 7:
		round = 0
		current_headline = null
		$AspectRatioContainer2/CenterContainer/Label.text = "Schau mal nach unten"
		return
	current_headline = headlines.headlines.pick_random()
	headline_vote_started.emit(current_headline)
	$AspectRatioContainer2/CenterContainer/Label.text = current_headline.text
	

func _on_timer_timeout() -> void:
	$ProgressBar.visible = false
	if current_headline:
		headline_vote_stopped.emit(current_headline)
	$AspectRatioContainer2/CenterContainer/Label.text = ""
	$BetweenTimer.start()


func _on_between_timer_timeout() -> void:
	display_new_headline()
