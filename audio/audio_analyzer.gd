## AudioAnalyzer - Real-time audio analysis using AudioEffectSpectrumAnalyzer
class_name AudioAnalyzer
extends Node


signal spectrum_updated(frequencies: Array[float])
signal beat_detected(strength: float)
signal bass_pulse(intensity: float)


## Configuration
@export var audio_bus: String = "Music"
@export var fft_size: AudioEffectSpectrumAnalyzerInstance.FFTSize = AudioEffectSpectrumAnalyzerInstance.FFT_SIZE_1024
@export var smoothing: float = 0.5

## Frequency bands (in Hz)
@export var sub_bass_range := Vector2(20, 60)
@export var bass_range := Vector2(60, 250)
@export var low_mid_range := Vector2(250, 500)
@export var mid_range := Vector2(500, 2000)
@export var high_mid_range := Vector2(2000, 4000)
@export var high_range := Vector2(4000, 20000)

## Beat detection
@export var beat_threshold: float = 0.6
@export var beat_cooldown: float = 0.15

## State
var _spectrum: AudioEffectSpectrumAnalyzerInstance = null
var _band_magnitudes: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _smoothed_magnitudes: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _last_beat_time: float = 0.0
var _bass_history: Array[float] = []
var _bass_history_size: int = 30


func _ready() -> void:
	_setup_spectrum_analyzer()


func _process(delta: float) -> void:
	if not _spectrum:
		return

	_analyze_spectrum()
	_detect_beat()


func _setup_spectrum_analyzer() -> void:
	var bus_idx := AudioServer.get_bus_index(audio_bus)
	if bus_idx < 0:
		push_warning("AudioAnalyzer: Bus '%s' not found" % audio_bus)
		return

	# Look for existing spectrum analyzer effect
	for i in range(AudioServer.get_bus_effect_count(bus_idx)):
		var effect := AudioServer.get_bus_effect(bus_idx, i)
		if effect is AudioEffectSpectrumAnalyzer:
			_spectrum = AudioServer.get_bus_effect_instance(bus_idx, i)
			return

	# Create new spectrum analyzer effect
	var analyzer := AudioEffectSpectrumAnalyzer.new()
	analyzer.fft_size = fft_size
	AudioServer.add_bus_effect(bus_idx, analyzer)
	_spectrum = AudioServer.get_bus_effect_instance(bus_idx, AudioServer.get_bus_effect_count(bus_idx) - 1)


func _analyze_spectrum() -> void:
	# Get magnitude for each frequency band
	_band_magnitudes[0] = _get_band_magnitude(sub_bass_range)
	_band_magnitudes[1] = _get_band_magnitude(bass_range)
	_band_magnitudes[2] = _get_band_magnitude(low_mid_range)
	_band_magnitudes[3] = _get_band_magnitude(mid_range)
	_band_magnitudes[4] = _get_band_magnitude(high_mid_range)
	_band_magnitudes[5] = _get_band_magnitude(high_range)

	# Apply smoothing
	for i in range(_band_magnitudes.size()):
		_smoothed_magnitudes[i] = lerp(_smoothed_magnitudes[i], _band_magnitudes[i], 1.0 - smoothing)

	spectrum_updated.emit(_smoothed_magnitudes.duplicate())

	# Track bass for pulse detection
	var bass := (_band_magnitudes[0] + _band_magnitudes[1]) * 0.5
	_bass_history.append(bass)
	if _bass_history.size() > _bass_history_size:
		_bass_history.pop_front()


func _get_band_magnitude(freq_range: Vector2) -> float:
	if not _spectrum:
		return 0.0

	var magnitude := _spectrum.get_magnitude_for_frequency_range(freq_range.x, freq_range.y)
	# Convert to linear scale and normalize
	return clamp((magnitude.x + magnitude.y) * 0.5, 0.0, 1.0)


func _detect_beat() -> void:
	if _bass_history.size() < 10:
		return

	var current_time := Time.get_ticks_msec() / 1000.0
	if current_time - _last_beat_time < beat_cooldown:
		return

	# Calculate average bass
	var avg_bass := 0.0
	for b in _bass_history:
		avg_bass += b
	avg_bass /= _bass_history.size()

	# Current bass
	var current_bass := (_band_magnitudes[0] + _band_magnitudes[1]) * 0.5

	# Detect beat as spike above average
	if current_bass > avg_bass * (1.0 + beat_threshold):
		var strength := clamp((current_bass - avg_bass) / avg_bass, 0.0, 1.0)
		_last_beat_time = current_time
		beat_detected.emit(strength)
		bass_pulse.emit(current_bass)


## === Public API ===

func get_sub_bass() -> float:
	return _smoothed_magnitudes[0]


func get_bass() -> float:
	return _smoothed_magnitudes[1]


func get_low_mid() -> float:
	return _smoothed_magnitudes[2]


func get_mid() -> float:
	return _smoothed_magnitudes[3]


func get_high_mid() -> float:
	return _smoothed_magnitudes[4]


func get_high() -> float:
	return _smoothed_magnitudes[5]


func get_all_bands() -> Array[float]:
	return _smoothed_magnitudes.duplicate()


func get_overall_loudness() -> float:
	var sum := 0.0
	for mag in _smoothed_magnitudes:
		sum += mag
	return sum / _smoothed_magnitudes.size()
