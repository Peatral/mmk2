extends Node

@export var particle_demo_scene = preload("res://scenes/demo/depth_particle_demo.tscn")

var demo_scene: Node3D

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("open_particle_demo"):
		get_viewport().set_input_as_handled()
		if demo_scene:
			demo_scene.queue_free()
			$MultiplayerMenu.visible = true
		else:
			demo_scene = particle_demo_scene.instantiate()
			add_child(demo_scene)
			$MultiplayerMenu.visible = false
