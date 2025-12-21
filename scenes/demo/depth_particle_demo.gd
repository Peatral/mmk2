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

func _process(_delta: float) -> void:
	camera.basis = KinectAutoload.kinect.Orientation
	camera.position = KinectAutoload.kinect.Transform.origin
	for person in persons.values():
		person.slerp_speed = slerp_speed
	

func _on_body_tracked(body: KinectBody):
	var person: TrackedPerson = TRACKED_PERSON_SCENE.instantiate()
	person.body = body
	person.color = Color(randf(), randf(), randf())
	add_child(person)
	persons[body] = person

func _on_body_untracked(body: KinectBody):
	var person := persons[body]
	persons.erase(body)
	person.queue_free()
