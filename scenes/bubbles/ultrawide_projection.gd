extends Control

var kinect := Kinect.new()

@export var tracker: KinectTracker

func _ready() -> void:
	$HeadlineDisplay.headline_vote_started.connect(MultiplayerManager._on_headline_vote_started)
	$HeadlineDisplay.headline_vote_stopped.connect(MultiplayerManager._on_headline_vote_stopped)
	
	KinectAutoload.start()
	for body in tracker.GetTrackedBodies():
		MultiplayerManager._on_body_tracked(body)
	tracker.BodyTracked.connect(MultiplayerManager._on_body_tracked)
	tracker.BodyUntracked.connect(MultiplayerManager._on_body_untracked)
	
