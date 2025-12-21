extends Node3D

var kinect := Kinect.new()

var tracker := preload("res://assets/resources/tracker.tres")
var depth_texture := preload("res://assets/resources/depth_texture.tres")

func start() -> void:
	if not kinect.IsRunning:
		kinect.Initialize(0)
		kinect.Start(tracker, depth_texture, 0, 5000, false, true)

func _exit_tree() -> void:
	kinect.Stop()
