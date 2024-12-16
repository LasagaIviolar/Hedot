extends PlayerSkin

@onready var offset_y: float = $Body/Head.position.y
@onready var body := $Body
@onready var head := $Body/Head

func _process(_delta: float) -> void:
	if body.animation == "Idle":
		if body.frame == 2 or body.frame == 6 or body.frame == 3 or body.frame == 7:
			head.position.y = offset_y + 1
		else:
			head.position.y = offset_y
		
		if head.animation == "Idle":
			head.frame = body.frame
	if body.animation == "Walk":
		if body.frame == 2 or body.frame == 6:
			head.position.y = offset_y + 1
		else:
			head.position.y = offset_y
		
		if head.animation == "Walk":
			head.frame = body.frame
	if body.animation == "Hurt":
		if body.frame == 2 or body.frame == 0:
			head.position.y = offset_y + 1
		else:
			head.position.y = offset_y
		
		if head.animation == "Idle":
			head.frame = body.frame

func walk_process() -> void:
	gigan_ground_attacks()
	if player.inputs[PlayerCharacter.Inputs.YINPUT] > 0 \
		and player.inputs_pressed[PlayerCharacter.Inputs.A]\
		and player.power.value >= 2.5 * 8:
		player.use_attack(PlayerCharacter.Attack.LASER)
	if player.inputs[PlayerCharacter.Inputs.YINPUT] > 0 \
		and player.inputs_pressed[PlayerCharacter.Inputs.B]\
		and player.power.value >= 2.5 * 8:
		player.use_attack(PlayerCharacter.Attack.LASER_DOWN)
	if player.inputs_pressed[PlayerCharacter.Inputs.START]\
		and player.power.value >= 2 * 8:
		player.use_attack(PlayerCharacter.Attack.BUZZSAW)
