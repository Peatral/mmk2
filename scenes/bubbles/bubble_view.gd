extends Node3D

var kinect := Kinect.new()

@export var slerp_speed: float = 10.0
@export var tracker: KinectTracker
@export var bubble_visualizer: BubbleVisualizer

var tracked_users: Dictionary[KinectBody, User] = {}

func _ready() -> void:
	KinectAutoload.start()
	for body in tracker.GetTrackedBodies():
		_on_body_tracked(body)
	tracker.BodyTracked.connect(_on_body_tracked)
	tracker.BodyUntracked.connect(_on_body_untracked)

func _process(delta: float) -> void:
	if bubble_visualizer and tracker:
		var slerp_factor: float = 1 - exp(-slerp_speed * delta)
		var users: Array[User] = []
		
		for body in tracked_users.keys():
			var user := tracked_users[body]
			user.position = user.position.slerp(body.TrackedData.Position, slerp_factor)
			users.append(user)
		
		var bubbles: Array[BubbleVisualizer.Bubble] = []
		bubbles.assign(users.map(_user_to_bubble))
		bubble_visualizer.bubbles = bubbles

func _user_to_bubble(user: User) -> BubbleVisualizer.Bubble:
	var bubble = BubbleVisualizer.Bubble.new()
	bubble.radius = 0.3
	bubble.position = Vector3(user.position.x, 0, user.position.z)
	bubble.data = (user.get_meta_position() + Vector2(1, 1)) * 0.5
	bubble.strength = user.get_certainty() * 0.3
	return bubble

func _on_body_tracked(body: KinectBody):
	var user = User.new()
	user.position = body.TrackedData.Position
	tracked_users[body] = user

func _on_body_untracked(body: KinectBody):
	tracked_users.erase(body)
