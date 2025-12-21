extends Node3D

var kinect := Kinect.new()

var tracker := preload("res://tracker.tres")
var depth_texture := preload("res://depth_texture.tres")

func _enter_tree() -> void:
	kinect.Initialize(0)
	kinect.Start(tracker, depth_texture, 0, 5000, false, true)

func _exit_tree() -> void:
	kinect.Stop()
