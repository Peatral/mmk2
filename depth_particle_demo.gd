extends Node3D

var kinect := Kinect.new()

@export var slerp_speed: float = 10.0
@export var color_texture: ImageTexture
@export var depth_texture: ImageTexture
@export var node: Node3D
@export var tracker: KinectTracker

var persons: Dictionary[KinectBody, TrackedPerson] = {}

const TRACKED_PERSON_SCENE: PackedScene = preload("res://tracked_person.tscn")

func _ready() -> void:
	tracker.BodyTracked.connect(_on_body_tracked)
	tracker.BodyUntracked.connect(_on_body_untracked)
	kinect.Initialize(0)
	kinect.Start(tracker, depth_texture, 0, 2000, false, true)

func _process(delta: float) -> void:
	node.basis = kinect.Orientation
	var slerp_factor: float = 1 - exp(-slerp_speed * delta)
	for body in persons.keys():
		var person: TrackedPerson = persons[body]
		person.position = person.position.slerp(body.Position, slerp_factor)

func _on_body_tracked(body: KinectBody):
	var person: TrackedPerson = TRACKED_PERSON_SCENE.instantiate()
	person.position = body.Position
	node.add_child(person)
	persons[body] = person

func _on_body_untracked(body: KinectBody):
	var person: TrackedPerson = persons[body]
	persons.erase(body)
	person.queue_free()
