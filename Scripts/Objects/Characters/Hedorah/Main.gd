extends PlayerSkin

@onready var offset_y: float = $Body/Head.position.y
@onready var body := $Body
@onready var head := $Body/Head

func _init() -> void:
	character_name = "Hedorah"
	bar_count = 8
	walk_frame_speed = 5

func _process(_delta: float) -> void:
	if body.animation == "Walk":
		if head.animation == "Walk":
			head.frame = body.frame

func walk_process() -> void:
	if player.inputs_pressed[PlayerCharacter.Inputs.A]:
		player.use_attack(PlayerCharacter.Attack.HEDORAH_PUNCH)
	if player.inputs[PlayerCharacter.Inputs.YINPUT] <= 0 \
		and player.inputs_pressed[PlayerCharacter.Inputs.B]:
		player.use_attack(PlayerCharacter.Attack.SLUDGE)
	if player.inputs[PlayerCharacter.Inputs.YINPUT] > 0 \
		and player.inputs_pressed[PlayerCharacter.Inputs.B]:
		player.use_attack(PlayerCharacter.Attack.SLUDGE_DOWN)
	if player.move_state == PlayerCharacter.State.WALK\
		and player.inputs_pressed[PlayerCharacter.Inputs.START]:
		player.animation_player.play("TransformationIn")
		player.get_sfx("HedorahMorph").play()
		print(1)
		player.animation_player.speed_scale =+ 1
		player.inputs[PlayerCharacter.Inputs.XINPUT] = 0
		player.inputs[PlayerCharacter.Inputs.YINPUT] = 0
		player.inputs_pressed[PlayerCharacter.Inputs.START] = false
		player.has_input = false
		player.velocity.y = 0
		var gravity_saved = player.gravity
		player.gravity = 0
		player.move_speed = 2 * 60
		await player.animation_player.animation_finished
		player.has_input = true
		player.gravity += gravity_saved
		
		player.move_state = PlayerCharacter.State.FLY
		player.state.current = player.move_state
		player.animation_player.play("Idle") 

func _on_animation_started(anim_name: StringName) -> void:
	var collision: CollisionShape2D = $Collision
	if anim_name == "TransformationIn" or anim_name == "Idle":
		collision = $FlyCollision
	if anim_name == "TransformationOut" or anim_name == "Walk":
		collision = $Collision
	player.set_collision(collision)
