extends Node3D

var kinect := Kinect.new()

var data_reference := preload("res://assets/resources/kinect_output.tres")
var depth_texture := preload("res://assets/resources/depth_texture.tres")

func start() -> void:
	if not kinect.IsRunning:
		kinect.Initialize(0)
		kinect.Start(data_reference, depth_texture, 0, 5000, false, true)
	

func apply_calibration_for_front() -> void:
	kinect.Transform = Transform3D(Basis.from_euler(Vector3(0, 0, 0)), Vector3(0, 1, 0))
	

func apply_calibration_for_left() -> void:
	kinect.Transform = Transform3D(Basis.from_euler(Vector3(0, PI/2, 0)), Vector3(1, 1, 0)) 
	

func apply_calibration_for_right() -> void:
	kinect.Transform = Transform3D(Basis.from_euler(Vector3(0, -PI/2, 0)), Vector3(-1, 1, 0))
	

func _exit_tree() -> void:
	kinect.Stop()
