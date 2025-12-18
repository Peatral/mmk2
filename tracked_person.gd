class_name TrackedPerson
extends Node3D

@export var color: Color = Color.HOT_PINK

func _process(delta: float) -> void:
	$MeshInstance3D.mesh.material.set("shader_parameter/color", color)
