extends Node3D

@export var bubble_visualizer: BubbleVisualizer

func _process(_delta: float) -> void:
	if bubble_visualizer:
		var bubbles: Array[BubbleVisualizer.Bubble] = []
		bubbles.assign(MultiplayerManager.users.map(_user_to_bubble))
		bubble_visualizer.bubbles = bubbles

func _user_to_bubble(user: User) -> BubbleVisualizer.Bubble:
	var bubble = BubbleVisualizer.Bubble.new()
	bubble.radius = 0.3
	bubble.position = Vector3(user.position.x, 0, user.position.z)
	bubble.data = (user.get_meta_position() * user.get_certainty() + Vector2(1, 1)) * 0.5
	bubble.strength = user.get_certainty() * 0.3
	return bubble
