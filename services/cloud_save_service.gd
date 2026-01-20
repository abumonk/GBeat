## CloudSaveService - Cloud storage for save data
## Stub implementation - replace with actual backend integration
class_name CloudSaveService
extends Node


signal save_uploaded(success: bool)
signal save_downloaded(data: Dictionary)
signal download_failed(error: String)
signal conflict_detected(local_data: Dictionary, cloud_data: Dictionary)
signal sync_completed()


enum SyncState {
	IDLE,
	UPLOADING,
	DOWNLOADING,
	CONFLICT,
}


## State
var current_state: SyncState = SyncState.IDLE
var last_sync_time: float = 0.0
var cloud_save_exists: bool = false

## Mock cloud storage
var _mock_cloud_data: Dictionary = {}
var _mock_cloud_timestamp: float = 0.0


## === Upload ===

func upload_save(save_data: Dictionary) -> void:
	if current_state != SyncState.IDLE:
		push_warning("CloudSaveService: Sync already in progress")
		return

	current_state = SyncState.UPLOADING
	print("CloudSaveService: Uploading save data...")

	await get_tree().create_timer(0.5).timeout

	# STUB: Store locally as mock
	_mock_cloud_data = save_data.duplicate(true)
	_mock_cloud_timestamp = Time.get_unix_time_from_system()
	cloud_save_exists = true

	current_state = SyncState.IDLE
	last_sync_time = _mock_cloud_timestamp
	save_uploaded.emit(true)


## === Download ===

func download_save() -> void:
	if current_state != SyncState.IDLE:
		push_warning("CloudSaveService: Sync already in progress")
		return

	current_state = SyncState.DOWNLOADING
	print("CloudSaveService: Downloading save data...")

	await get_tree().create_timer(0.3).timeout

	if _mock_cloud_data.is_empty():
		current_state = SyncState.IDLE
		download_failed.emit("No cloud save found")
		return

	current_state = SyncState.IDLE
	last_sync_time = Time.get_unix_time_from_system()
	save_downloaded.emit(_mock_cloud_data.duplicate(true))


## === Sync ===

func sync_save(local_data: Dictionary, local_timestamp: float) -> void:
	if current_state != SyncState.IDLE:
		push_warning("CloudSaveService: Sync already in progress")
		return

	print("CloudSaveService: Syncing save data...")

	await get_tree().create_timer(0.3).timeout

	if _mock_cloud_data.is_empty():
		# No cloud save, upload local
		upload_save(local_data)
		return

	# Check for conflict
	if _mock_cloud_timestamp > local_timestamp:
		# Cloud is newer - potential conflict
		current_state = SyncState.CONFLICT
		conflict_detected.emit(local_data, _mock_cloud_data.duplicate(true))
		return

	# Local is newer or same, upload
	upload_save(local_data)


func resolve_conflict(use_cloud: bool) -> void:
	if current_state != SyncState.CONFLICT:
		return

	current_state = SyncState.IDLE

	if use_cloud:
		save_downloaded.emit(_mock_cloud_data.duplicate(true))
	else:
		# Keep local - will upload on next sync
		pass

	sync_completed.emit()


## === Utility ===

func has_cloud_save() -> bool:
	return cloud_save_exists


func get_cloud_timestamp() -> float:
	return _mock_cloud_timestamp


func get_last_sync_time() -> float:
	return last_sync_time


func get_state() -> SyncState:
	return current_state


func is_syncing() -> bool:
	return current_state != SyncState.IDLE


func delete_cloud_save() -> void:
	print("CloudSaveService: Deleting cloud save...")
	_mock_cloud_data = {}
	_mock_cloud_timestamp = 0.0
	cloud_save_exists = false
