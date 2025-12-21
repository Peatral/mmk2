class_name TrackedPerson
extends Node3D

@export var slerp_speed = 5.0
@export var color: Color = Color.HOT_PINK
var body: KinectBody

func _ready() -> void:
	position = body.TrackedData.Position

func _process(delta: float) -> void:
	var slerp_factor: float = 1 - exp(-slerp_speed * delta)
	position = position.slerp(body.TrackedData.Position, slerp_factor)
	$MeshInstance3D.mesh.material.set("shader_parameter/color", Color.RED if body.TrackedData.ArmRaised else color)
