extends Node3D

var kinect := Kinect.new()

@export var color_texture: ImageTexture
@export var depth_texture: ImageTexture
@export var node: Node3D
@export var tracker: KinectTracker

func _ready() -> void:
	kinect.Initialize(0)
	start()

func _process(delta: float) -> void:
	node.basis = kinect.Orientation

func start() -> void:
	kinect.Stop()
	kinect.Start(tracker, depth_texture, 0, 2000, false, true)
