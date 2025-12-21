extends Node

const DEFAULT_PORT: int = 7777
var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

func _ready():
	multiplayer.peer_connected.connect(client_connected)
	multiplayer.peer_disconnected.connect(client_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(server_disconnected)

func create_server():
	peer.create_server(DEFAULT_PORT)
	multiplayer.set_multiplayer_peer(peer)
	print("Server created")

func connect_to_server(ip_address):
	peer.create_client(ip_address, DEFAULT_PORT)
	multiplayer.set_multiplayer_peer(peer)
	print("Connecting to server")

func client_connected(id):
	print("Client connected: " + str(id))

func client_disconnected(id):
	print("Client disconnected: " + str(id))

func connected_to_server():
	print("Connected to server")

func connection_failed():
	print("Connection failed")

func server_disconnected():
	print("Server disconnected")
