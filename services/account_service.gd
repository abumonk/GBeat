## AccountService - Player authentication and account management
## Stub implementation - replace with actual backend integration
class_name AccountService
extends Node


signal login_success(player_data: Dictionary)
signal login_failed(error: String)
signal logout_completed()
signal account_created(player_data: Dictionary)
signal account_creation_failed(error: String)
signal profile_updated(player_data: Dictionary)


enum AuthProvider {
	EMAIL,
	STEAM,
	GUEST,
}


## Account state
var is_logged_in: bool = false
var current_player_id: String = ""
var current_player_data: Dictionary = {}
var auth_provider: AuthProvider = AuthProvider.GUEST


func _ready() -> void:
	# Auto-login as guest for offline play
	_login_as_guest()


## === Login Methods ===

func login_with_email(email: String, password: String) -> void:
	# STUB: Replace with actual authentication
	print("AccountService: Login attempt with email: %s" % email)

	# Simulate network delay
	await get_tree().create_timer(0.5).timeout

	# For now, always succeed with mock data
	var player_data := {
		"player_id": "email_%s" % email.md5_text().substr(0, 8),
		"display_name": email.split("@")[0],
		"email": email,
		"auth_provider": "email",
		"created_at": Time.get_datetime_string_from_system(),
	}

	_complete_login(player_data, AuthProvider.EMAIL)


func login_with_steam() -> void:
	# STUB: Replace with Steam SDK integration
	print("AccountService: Steam login attempt")

	await get_tree().create_timer(0.5).timeout

	# Mock Steam login
	var player_data := {
		"player_id": "steam_%d" % randi(),
		"display_name": "SteamPlayer",
		"steam_id": str(randi()),
		"auth_provider": "steam",
		"created_at": Time.get_datetime_string_from_system(),
	}

	_complete_login(player_data, AuthProvider.STEAM)


func _login_as_guest() -> void:
	var player_data := {
		"player_id": "guest_%d" % randi(),
		"display_name": "Guest",
		"auth_provider": "guest",
		"created_at": Time.get_datetime_string_from_system(),
	}

	_complete_login(player_data, AuthProvider.GUEST)


func _complete_login(player_data: Dictionary, provider: AuthProvider) -> void:
	is_logged_in = true
	current_player_id = player_data.get("player_id", "")
	current_player_data = player_data
	auth_provider = provider

	login_success.emit(player_data)


## === Logout ===

func logout() -> void:
	is_logged_in = false
	current_player_id = ""
	current_player_data = {}
	auth_provider = AuthProvider.GUEST

	logout_completed.emit()

	# Re-login as guest
	_login_as_guest()


## === Account Creation ===

func create_account(email: String, password: String, display_name: String) -> void:
	# STUB: Replace with actual account creation
	print("AccountService: Creating account for: %s" % email)

	await get_tree().create_timer(0.5).timeout

	var player_data := {
		"player_id": "email_%s" % email.md5_text().substr(0, 8),
		"display_name": display_name,
		"email": email,
		"auth_provider": "email",
		"created_at": Time.get_datetime_string_from_system(),
	}

	account_created.emit(player_data)
	_complete_login(player_data, AuthProvider.EMAIL)


## === Profile Management ===

func update_display_name(new_name: String) -> void:
	# STUB: Replace with actual backend call
	current_player_data["display_name"] = new_name
	profile_updated.emit(current_player_data)


func update_profile(updates: Dictionary) -> void:
	# STUB: Replace with actual backend call
	for key in updates.keys():
		current_player_data[key] = updates[key]
	profile_updated.emit(current_player_data)


## === Getters ===

func get_player_id() -> String:
	return current_player_id


func get_display_name() -> String:
	return current_player_data.get("display_name", "Guest")


func get_player_data() -> Dictionary:
	return current_player_data.duplicate()


func is_guest() -> bool:
	return auth_provider == AuthProvider.GUEST


func get_auth_provider() -> AuthProvider:
	return auth_provider
