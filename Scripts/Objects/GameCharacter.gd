class_name GameCharacter
extends CharacterBody2D

enum Type {
	GODZILLA,
	MOTHRA,
}

# States in "States" node of the player should be
# in the same order as here.
enum State {
	WALK,
	FLY,
	LEVEL_INTRO,
	HURT,
	DEAD,
	ATTACK,
}

enum Attack {
	# Attacks that are common for ground characters
	PUNCH,
	KICK,
	
	# Godzilla attacks
	TAIL_WHIP,
	HEAT_BEAM,
	
	# Mothra attacks
	EYE_BEAM,
	WING_ATTACK,
}

const CHARACTER_NAMES: Array[String] = [
	"Godzilla",
	"Mothra",
]

const BaseBarCount: Array[int] = [
	6, # Godzilla
	8, # Mothra
]

@export var is_player := true
@export var enable_intro := true
@export var enable_attacks := true
## If true, the player object will face the movement direction
@export var allow_direction_changing := false

@onready var collision: CollisionShape2D = $Collision
# TODO: reusable state machine
@onready var states_list: Array[Node] = $States.get_children()
@onready var health: Node = $HealthComponent
@onready var power: Node = $PowerComponent

var state := State.LEVEL_INTRO: set = _set_state
var move_state := State.WALK

var character := GameCharacter.Type.GODZILLA
var move_speed := 0.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var level := 1
# TODO: move score to Global singleton
var score := 0
var save_position: Array[Vector2]

var direction: int = 1:
	set(value):
		if value != 0 && signi(value) != direction:
			direction = signi(value)
			scale.x = -1

var body: AnimatedSprite2D
var skin: Node2D
var animation_player: AnimationPlayer

# This is done so the bosses and players use the same script
# and allow to play as bosses and test their attacks.
enum Inputs {
	XINPUT, YINPUT, B, A, START, SELECT,
}

var has_input := true
var inputs := []
var inputs_pressed := []
const INPUT_ACTIONS = [["Left", "Right"], ["Up", "Down"], "B", "A", "Start", "Select"]

signal intro_ended
signal life_amount_changed(new_value: float)
signal level_amount_changed(new_value: int, new_bar_count: int)

func _ready() -> void:
	if is_player:
		Global.player = self
		if enable_intro:
			position.x = -40
	
	inputs.resize(Inputs.size())
	inputs_pressed.resize(Inputs.size())
	save_position.resize(60)
	
	# Several default values
	move_speed = 1 * 60
	load_state()
			
	await Global.get_current_scene().ready
		
	# GameCharacter-specific setup	
	var new_skin: Node2D
	match character:
		GameCharacter.Type.GODZILLA:
			# Skin is already Godzilla, so we just move it above everything else
			move_child($Skin, -1)
			get_sfx("Step").stream = load("res://Audio/SFX/GodzillaStep.ogg")
			get_sfx("Roar").stream = load("res://Audio/SFX/GodzillaRoar.ogg")
			move_state = State.WALK
			set_collision(Vector2(20, 56), Vector2(0, -1))
			
			# We set the character-specific position so when the character
			# walks in a sudden frame change won't happen
			# (walk_frame is set to 0 when the characters gets control)
			if is_player and enable_intro:
				position.x = -35
		
		GameCharacter.Type.MOTHRA:
			new_skin = preload("res://Objects/Characters/Mothra.tscn").instantiate()
			get_sfx("Step").stream = load("res://Audio/SFX/MothraStep.ogg")
			get_sfx("Roar").stream = load("res://Audio/SFX/GodzillaRoar.ogg")
			move_state = State.FLY
			position.y -= 40
			move_speed = 2 * 60
			set_collision(Vector2(36, 14), Vector2(-4, 1))
			
			if is_player and enable_intro:
				position.x = -37
			
	# Setup for all characters
	if new_skin:
		var prev_skin: Node2D = $Skin
		remove_child(prev_skin)
		prev_skin.queue_free()
		
		skin.name = "Skin"
		add_child(skin)
	
	skin = $Skin
	body = $Skin/Body
	animation_player = $Skin/AnimationPlayer
	move_child(collision, -1)
	
	if is_flying():
		animation_player.play("Idle")
	
	if not enable_intro:
		state = move_state
		if is_player:
			intro_ended.emit()
	
	for i in states_list:
		i.state_init()
		if i == states_list[state]:
			i.enable()
			i.state_entered()
		else:
			i.disable()
		
func _physics_process(delta: float) -> void:
	# The character should come from outside the camera from the left side
	# of the screen, so we shouldn't limit the position unless the player
	# got control of the character.
	if velocity.x < 0 \
		and position.x <= get_viewport().get_camera_2d().limit_left + 16:
		position.x = get_viewport().get_camera_2d().limit_left + 16
		velocity.x = 0

	if state != State.DEAD and not is_on_floor() and not is_flying():
		velocity.y += gravity * delta

	move_and_slide()
	save_position.pop_back()
	save_position.insert(0, Vector2(position))

func _process(_delta: float) -> void:
	process_input()

func _set_state(new_state: State) -> void:
	if state == new_state:
		return
	
	var old_state_node := states_list[state]
	var new_state_node := states_list[new_state]
	
	old_state_node.state_exited()
	old_state_node.disable()
	new_state_node.enable()
	new_state_node.state_entered()
	
	state = new_state
	
func process_input() -> void:
	if has_input:
		inputs[Inputs.XINPUT] = roundi(Input.get_axis(INPUT_ACTIONS[0][0], INPUT_ACTIONS[0][1]))
		inputs[Inputs.YINPUT] = roundi(Input.get_axis(INPUT_ACTIONS[1][0], INPUT_ACTIONS[1][1]))
		
		inputs_pressed[Inputs.XINPUT] = int(Input.is_action_just_pressed("Right")) \
			- int(Input.is_action_just_pressed("Left"))
		inputs_pressed[Inputs.YINPUT] = int(Input.is_action_just_pressed("Down")) \
			- int(Input.is_action_just_pressed("Up"))
			
		for i in range(Inputs.B, Inputs.size()):
			inputs[i] = Input.is_action_pressed(INPUT_ACTIONS[i])
			inputs_pressed[i] = Input.is_action_just_pressed(INPUT_ACTIONS[i])
	
# TODO: attack component
func use_attack(type: Attack) -> void:
	if not enable_attacks:
		return
	$States/Attack.use(type)
	
func set_level(value: int) -> void:
	if not is_player or level == value:
		return
	level = value
	
	var bars := GameCharacter.calculate_bar_count(character, level)
	var bar_value := bars * 8
	
	power.max_value = bar_value
	power.value = bar_value
	health.max_value = bar_value
	health.value = bar_value
	
	level_amount_changed.emit(level, bars)
	
# Pass 0 to update the score meter
func add_score(amount: int) -> void:
	if not is_player:
		return

	var score_meter: Label = \
		Global.get_current_scene().\
		get_HUD().get_node("PlayerCharacter/ScoreMeter")
	score += amount
	if is_player:
		score_meter.text = str(score)
	
func get_sfx(sfx_name: String) -> AudioStreamPlayer:
	return get_node("SFX/" + sfx_name)
	
func get_character_name() -> String:
	return CHARACTER_NAMES[character]
	
func is_flying() -> bool:
	return character == Type.MOTHRA
	
func set_collision(size: Vector2, offset: Vector2) -> void:
	collision.shape.size = size
	collision.position = offset
	
func is_hurtable() -> bool:
	return state not in [State.LEVEL_INTRO, State.HURT, State.DEAD]

func _on_health_damaged(amount: float, hurt_time: float) -> void:
	life_amount_changed.emit(health.value)
	if hurt_time < 0:
		hurt_time = 0.6
	if hurt_time > 0:
		$States/Hurt.hurt_time = hurt_time
		state = State.HURT

func _on_health_dead() -> void:
	life_amount_changed.emit(0)
	state = State.DEAD

func _on_health_healed(amount: float) -> void:
	life_amount_changed.emit(health.value)
	
func load_state(data: Dictionary = {}) -> void:
	if data.is_empty():
		var bar_value := GameCharacter.calculate_bar_count(character, level) * 8
		power.max_value = bar_value
		power.value = bar_value
		health.max_value = bar_value
		health.value = bar_value
		return
		
	var bar_value: float = data.bars * 8
	set_level(data.level)
	
	health.max_value = bar_value
	health.value = data.hp
	power.max_value = bar_value
	power.value = bar_value
	
	score = Global.board.board_data.player_score
	add_score(0)
	
	# TODO: xp
	
func save_state(data: Dictionary) -> void:
	data.hp = health.value
	data.bars = power.max_value / 8
	data.level = level

static func calculate_bar_count(char_id: GameCharacter.Type, char_level: int) -> int:
	return BaseBarCount[char_id] + char_level - 1
