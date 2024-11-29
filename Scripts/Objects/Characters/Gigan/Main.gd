extends PlayerSkin

@onready var offset_y: float = $Body/Head.position.y
@onready var body := $Body
@onready var head := $Body/Head

func _process(_delta: float) -> void:
	if body.animation == "Idle":
		if head.animation == "Idle":
			head.frame = body.frame

func walk_process() -> void:
	common_ground_attacks()
	if player.inputs[PlayerCharacter.Inputs.YINPUT] > 0 \
		and player.inputs_pressed[PlayerCharacter.Inputs.A]\
		and player.power.value >= 2.5 * 8:
		player.use_attack(PlayerCharacter.Attack.LASER)
	if player.inputs[PlayerCharacter.Inputs.YINPUT] > 0 \
		and player.inputs_pressed[PlayerCharacter.Inputs.B]\
		and player.power.value >= 2.5 * 8:
		player.use_attack(PlayerCharacter.Attack.LASER_DOWN)
