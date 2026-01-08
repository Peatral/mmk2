extends Node

enum ScreenType {
	HEADLINES,
	BUBBLES
}

var screen_type: ScreenType = ScreenType.HEADLINES

var slerp_speed: float = 10.0
var tracked_users: Dictionary[KinectBody, User] = {}
var users: Array[User] = []

var active_headline: Headline = null
var voted_users: Array[User] = []

func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	var slerp_factor: float = 1 - exp(-slerp_speed * delta)
	users = []
	for body in tracked_users.keys():
		var user := tracked_users[body]
		user.position = user.position.slerp(body.TrackedData.Position, slerp_factor)
		users.append(user)
	_sync_users_to_clients()


func _on_body_tracked(body: KinectBody) -> void:
	var user := User.new()
	user.position = body.TrackedData.Position
	tracked_users[body] = user
	body.TrackedData.ArmRaisedChanged.connect(_on_user_arm_raised_changed.bind(user))

func _on_body_untracked(body: KinectBody) -> void:
	tracked_users.erase(body)

func _on_headline_vote_started(headline: Headline) -> void:
	active_headline = headline
	voted_users = []
	

func _on_headline_vote_stopped(_headline: Headline) -> void:
	active_headline = null
	voted_users = []

func _on_user_arm_raised_changed(arm_raised: bool, user: User) -> void:
	if not arm_raised:
		return
	if active_headline == null:
		return
	if voted_users.has(user):
		return
	voted_users.append(user)
	user.like_headline(active_headline)

func _sync_users_to_clients() -> void:
	_update_users_on_client.rpc(users.map(User.serialize))

@rpc("call_remote", "authority", "unreliable_ordered")
func _update_users_on_client(users_data: Array) -> void:
	users.assign(users_data.map(User.deserialize))
