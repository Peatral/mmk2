extends Node3D

var kinect := Kinect.new()

var tracker := preload("res://tracker.tres")
var depth_texture := preload("res://depth_texture.tres")

func _ready() -> void:
	kinect.Initialize(0)
	kinect.Start(tracker, depth_texture, 0, 2000, false, true)
