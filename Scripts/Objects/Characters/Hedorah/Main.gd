extends PlayerSkin

@onready var offset_y: float = $Body/Head.position.y
@onready var body := $Body
@onready var head := $Body/Head

var attack_timer := Timer.new()
var timer := Timer.new()

func state_init() -> void:
	attack_timer.one_shot = true
	add_child(attack_timer)
	timer.one_shot = true
	add_child(timer)

func _process(_delta: float) -> void:
	if body.animation == "Walk":
		if head.animation == "Walk":
			head.frame = body.frame

func walk_process() -> void:
	if player.inputs_pressed[PlayerCharacter.Inputs.A]:
		player.use_attack(PlayerCharacter.Attack.HEDORAH_PUNCH)
	if player.inputs[PlayerCharacter.Inputs.YINPUT] <= 0 \
		and player.inputs_pressed[PlayerCharacter.Inputs.B]\
		and attack_timer.is_stopped():
		player.use_attack(PlayerCharacter.Attack.SLUDGE)
		attack_timer.start(0.2)
	if player.inputs[PlayerCharacter.Inputs.YINPUT] > 0 \
		and player.inputs_pressed[PlayerCharacter.Inputs.B]\
		and attack_timer.is_stopped():
		player.use_attack(PlayerCharacter.Attack.SLUDGE_DOWN)
		attack_timer.start(0.2)
	if player.move_state == PlayerCharacter.State.WALK\
		and player.inputs[PlayerCharacter.Inputs.YINPUT] <= 0 \
		and player.inputs_pressed[PlayerCharacter.Inputs.START] \
		and player.health.value >= 3 * 8\
		and attack_timer.is_stopped():
		var had_input := player.has_input
		player.has_input = false
		player.velocity.y = 0
		var gravity_saved = player.gravity
		player.gravity = 0
		player.move_speed = 2 * 60
		player.move_state = PlayerCharacter.State.FLY
		player.state.current = player.move_state
		player.animation_player.play("TransformationIn")
		player.get_sfx("HedorahMorph").play()
		player.animation_player.speed_scale =+ 1
		player.inputs[PlayerCharacter.Inputs.XINPUT] = 0.0
		player.inputs[PlayerCharacter.Inputs.YINPUT] = 0.0
		player.inputs_pressed[PlayerCharacter.Inputs.START] = false
		await get_tree().create_timer(0.5, false).timeout
		player.has_input = had_input
		player.gravity += gravity_saved
		
		player.animation_player.play("Idle") 
		
	if player.inputs[PlayerCharacter.Inputs.YINPUT] > 0 \
		and player.inputs_pressed[PlayerCharacter.Inputs.START]\
		and player.power.value >= 6 * 8\
		and attack_timer.is_stopped():
		player.use_attack(PlayerCharacter.Attack.LASERBEAM)
		attack_timer.start(0.65)
		
func _on_animation_started(anim_name: StringName) -> void:
	var collision: CollisionShape2D = $Collision
	if anim_name == "TransformationIn" or anim_name == "Idle" or anim_name == "Hurt":
		collision = $FlyCollision
	if anim_name == "TransformationOut" or anim_name == "Walk":
		collision = $Collision
	player.set_collision(collision)
