class_name User
extends RefCounted

const HEADLINES: HeadlineContainer = preload("res://assets/resources/headlines.tres")


var liked_headlines: Array[Headline] = []
var position: Vector3

func like_headline(headline: Headline) -> void:
	liked_headlines.append(headline)

func get_meta_position() -> Vector2:
	var total_spectrum := Vector2.ZERO
	var total_answered := 0
	for headline in liked_headlines:
		if headline.political_orientation == Headline.PoliticalOrientation.Center:
			continue
		var spectrum := _get_headline_spectrum(headline)
		total_spectrum += spectrum
		total_answered += 1
	if total_answered > 0:
		total_spectrum /= total_answered
	return total_spectrum

func get_certainty() -> float:
	return clamp(liked_headlines.size() / 3.0, 0.0, 1.0)

func _get_headline_spectrum(headline) -> Vector2:
	var spectrum = Vector2.ZERO

	var orientation = headline.political_orientation
	if orientation == Headline.PoliticalOrientation.Left:
		spectrum.y = -1
	elif orientation == Headline.PoliticalOrientation.Right:
		spectrum.y = 1
	
	var realness = headline.realness
	if realness == Headline.Realness.Lie:
		spectrum.x = -1
	elif orientation == Headline.Realness.Truth:
		spectrum.x = 1
	
	return spectrum

static func serialize(user: User) -> Dictionary:
	var liked_indices := PackedInt32Array()
	for headline in user.liked_headlines:
		var idx := HEADLINES.headlines.find(headline)
		if idx != -1:
			liked_indices.append(idx)
	return {
		"pos": user.position,
		"likes": liked_indices
	}

static func deserialize(data: Dictionary) -> User:
	var user := User.new()
	user.position = data.pos
	for idx in data.likes:
		if idx >= 0 and idx < HEADLINES.headlines.size():
			user.liked_headlines.append(HEADLINES.headlines[idx])
	return user
