extends Node3D

var kinect := Kinect.new()

@export var slerp_speed: float = 10.0
@export var tracker: KinectTracker
@export var bubble_visualizer: BubbleVisualizer

var tracked_bubbles: Dictionary[KinectBody, BubbleVisualizer.Bubble] = {}

func _ready() -> void:
	KinectAutoload.start()
	for body in tracker.GetTrackedBodies():
		_on_body_tracked(body)
	tracker.BodyTracked.connect(_on_body_tracked)
	tracker.BodyUntracked.connect(_on_body_untracked)

func _process(delta: float) -> void:
	if bubble_visualizer and tracker:
		var slerp_factor: float = 1 - exp(-slerp_speed * delta)
		var bubbles_list: Array[BubbleVisualizer.Bubble] = []
		
		for body in tracked_bubbles.keys():
			var bubble := tracked_bubbles[body]
			bubble.position = bubble.position.slerp(body.TrackedData.Position, slerp_factor)
			bubbles_list.append(bubble)
			
		bubble_visualizer.bubbles = bubbles_list

func _on_body_tracked(body: KinectBody):
	var bubble := BubbleVisualizer.Bubble.new()
	bubble.position = body.TrackedData.Position
	bubble.radius = 0.2
	bubble.strength = 0.3
	bubble.data = Vector2(0, 0)
	tracked_bubbles[body] = bubble

func _on_body_untracked(body: KinectBody):
	tracked_bubbles.erase(body)
