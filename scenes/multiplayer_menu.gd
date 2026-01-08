extends Control

@export var ip_address_edit: LineEdit
@export var main_scene: PackedScene
@export var floor_scene: PackedScene


func _create_server() -> void:
	var port = int(ip_address_edit.text)
	NetworkManager.create_server(port)
	get_window().size = Vector2i(1920, 1080)
	get_window().mode = Window.MODE_FULLSCREEN
	get_tree().change_scene_to_packed(main_scene)


func _connect_to_server() -> void:
	var ip_address = ip_address_edit.text
	var port = int(ip_address_edit.text)
	NetworkManager.connect_to_server(ip_address, port)
	get_window().size = Vector2i(1920, 1080)
	get_window().mode = Window.MODE_FULLSCREEN
	MultiplayerManager.screen_type = MultiplayerManager.ScreenType.BUBBLES
	get_tree().change_scene_to_packed(floor_scene)


func _on_screen_button_pressed() -> void:
	_create_server()
	KinectAutoload.apply_calibration_for_front()

func _on_floor_back_button_pressed() -> void:
	_connect_to_server()
	# KinectAutoload.apply_calibration_for_left()

func _on_floor_front_button_pressed() -> void:
	_connect_to_server()
	# KinectAutoload.apply_calibration_for_right()
