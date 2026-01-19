## AnimationTest - Test scene for character animations
extends Node3D


@onready var character: HumanoidCharacter = $HumanoidCharacter
@onready var animator: HumanoidAnimator = $HumanoidCharacter/HumanoidAnimator
@onready var anim_label: Label3D = $AnimLabel
@onready var camera: Camera3D = $Camera3D

var current_category: AnimationData.Category = AnimationData.Category.IDLE
var current_index: int = 0
var animations_in_category: Array[String] = []


func _ready() -> void:
	# Initialize animations
	AnimationData.init_defaults()

	# Setup animator reference
	animator.skeleton = character.skeleton

	# Load first category
	_load_category(AnimationData.Category.IDLE)


func _process(_delta: float) -> void:
	# Update label
	if animator.current_animation:
		anim_label.text = animator.current_animation.name + "\n[" + _category_name(current_category) + "]"
	else:
		anim_label.text = "No animation"


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		_next_animation()
	elif event.is_action_pressed("ui_left"):
		_prev_animation()
	elif event.is_action_pressed("ui_up"):
		_next_category()
	elif event.is_action_pressed("ui_down"):
		_prev_category()
	elif event.is_action_pressed("ui_accept"):
		if animator.is_playing:
			animator.pause()
		else:
			animator.resume()

	# Number keys for categories
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_load_category(AnimationData.Category.IDLE)
			KEY_2:
				_load_category(AnimationData.Category.MOVEMENT)
			KEY_3:
				_load_category(AnimationData.Category.COMBAT)
			KEY_4:
				_load_category(AnimationData.Category.DANCE)
			KEY_5:
				_load_category(AnimationData.Category.EMOTE)
			KEY_R:
				# Randomize character appearance
				character.randomize_appearance()


func _load_category(category: AnimationData.Category) -> void:
	current_category = category
	animations_in_category = animator.get_animations_by_category(category)
	current_index = 0
	if animations_in_category.size() > 0:
		animator.play(animations_in_category[0])


func _next_animation() -> void:
	if animations_in_category.is_empty():
		return
	current_index = (current_index + 1) % animations_in_category.size()
	animator.play(animations_in_category[current_index])


func _prev_animation() -> void:
	if animations_in_category.is_empty():
		return
	current_index = (current_index - 1 + animations_in_category.size()) % animations_in_category.size()
	animator.play(animations_in_category[current_index])


func _next_category() -> void:
	var cat_count := AnimationData.Category.size()
	current_category = ((current_category as int) + 1) % cat_count as AnimationData.Category
	_load_category(current_category)


func _prev_category() -> void:
	var cat_count := AnimationData.Category.size()
	current_category = ((current_category as int) - 1 + cat_count) % cat_count as AnimationData.Category
	_load_category(current_category)


func _category_name(cat: AnimationData.Category) -> String:
	match cat:
		AnimationData.Category.IDLE:
			return "IDLE"
		AnimationData.Category.MOVEMENT:
			return "MOVEMENT"
		AnimationData.Category.COMBAT:
			return "COMBAT"
		AnimationData.Category.DANCE:
			return "DANCE"
		AnimationData.Category.EMOTE:
			return "EMOTE"
	return "UNKNOWN"
