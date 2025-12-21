extends Node3D

var kinect := Kinect.new()

var data_reference := preload("res://assets/resources/kinect_output.tres")
var depth_texture := preload("res://assets/resources/depth_texture.tres")

func start() -> void:
	if not kinect.IsRunning:
		kinect.Initialize(0)
		kinect.Start(data_reference, depth_texture, 0, 5000, false, true)

func _exit_tree() -> void:
	kinect.Stop()
