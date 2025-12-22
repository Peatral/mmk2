class_name User
extends RefCounted

var liked_headlines: Array[Headline] = []
var position: Vector3

func like_headline(headline: Headline) -> void:
	liked_headlines.append(headline)

func get_meta_position() -> Vector2:
	var total_spectrum = Vector2.ZERO
	for headline in liked_headlines:
		var spectrum = _get_headline_spectrum(headline)
		total_spectrum += spectrum
	var total_answered = liked_headlines.size()
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
