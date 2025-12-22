class_name Headline
extends Resource

enum PoliticalOrientation {
	Left = 0,
	Center = 1,
	Right = 2,
}

enum Realness {
	Lie = 0,
	Halftruth = 1,
	Truth = 2
}

@export
var text: String
@export
var political_orientation := PoliticalOrientation.Center
@export
var realness := Realness.Truth
