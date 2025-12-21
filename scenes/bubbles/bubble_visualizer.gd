class_name BubbleVisualizer
extends MeshInstance3D

var bubbles: Array[Bubble] = []

func _process(delta: float) -> void:
	mesh.material.set(
		"shader_parameter/bubble_count",
		bubbles.size()
	)
	mesh.material.set(
		"shader_parameter/bubble_positions",
		bubbles.map(func(bubble): return bubble.position)
	)
	mesh.material.set(
		"shader_parameter/bubble_data",
		bubbles.map(func(bubble): return Vector4(bubble.radius, bubble.strength, bubble.data.x, bubble.data.y))
	)

class Bubble:
	var position: Vector3
	var radius: float
	var strength: float
	var data: Vector2
