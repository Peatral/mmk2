extends Control

@export var ip_address_edit: LineEdit
@export var main_scene: PackedScene

func _on_client_button_pressed() -> void:
	NetworkManager.create_server()
	get_tree().change_scene_to_packed(main_scene)


func _on_server_button_pressed() -> void:
	var ip_address = ip_address_edit.text
	NetworkManager.connect_to_server(ip_address)
	get_tree().change_scene_to_packed(main_scene)
