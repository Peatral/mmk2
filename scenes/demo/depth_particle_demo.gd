extends Node3D

@export var slerp_speed: float = 10.0
@export var camera: Node3D
@export var tracker: KinectTracker

var persons: Dictionary[KinectBody, TrackedPerson] = {}

const TRACKED_PERSON_SCENE: PackedScene = preload("res://scenes/demo/tracked_person.tscn")

func _ready() -> void:
	KinectAutoload.start()
	for body in tracker.GetTrackedBodies():
		_on_body_tracked(body)
	tracker.BodyTracked.connect(_on_body_tracked)
	tracker.BodyUntracked.connect(_on_body_untracked)

func _process(delta: float) -> void:
	camera.basis = KinectAutoload.kinect.Orientation
	var slerp_factor: float = 1 - exp(-slerp_speed * delta)
	for body in persons.keys():
		var person := persons[body]
		person.position = person.position.slerp(body.Position, slerp_factor)

func _on_body_tracked(body: KinectBody):
	var person: TrackedPerson = TRACKED_PERSON_SCENE.instantiate()
	person.position = body.Position
	person.color = Color(randf(), randf(), randf())
	add_child(person)
	persons[body] = person

func _on_body_untracked(body: KinectBody):
	var person := persons[body]
	persons.erase(body)
	person.queue_free()
