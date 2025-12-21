extends Node3D

var kinect := Kinect.new()

var data_reference := preload("res://assets/resources/kinect_output.tres")
var depth_texture := preload("res://assets/resources/depth_texture.tres")

func start() -> void:
	if not kinect.IsRunning:
		kinect.Initialize(0)

		# Right
		kinect.Transform = Transform3D(Basis.from_euler(Vector3(0, -PI/2, 0)), Vector3(-1, 1, 0))
		# Left
		# kinect.Transform = Transform3D(Basis.from_euler(Vector3(0, PI/2, 0)), Vector3(1, 1, 0))
		# Front
		#kinect.Transform = Transform3D(Basis.from_euler(Vector3(0, 0, 0)), Vector3(0, 1, 0))

		kinect.Start(data_reference, depth_texture, 0, 5000, false, true)

func _exit_tree() -> void:
	kinect.Stop()
