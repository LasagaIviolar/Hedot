extends "res://Scripts/Objects/Characters/PlayerState.gd"

const YLIMIT = 72
var floor_checking: Area2D
var attack_timer := Timer.new()
var flash_player: AnimationPlayer

func state_init() -> void:
	floor_checking = player.get_node("MothraFloorChecking")
	attack_timer.one_shot = true
	add_child(attack_timer)
	flash_player = player.skin.get_node("FlashPlayer")

func _physics_process(delta: float) -> void:
	move(delta)
		
func _process(_delta: float) -> void:
	if player.character == PlayerCharacter.Type.MOTHRA:
		if (player.inputs_pressed[player.Inputs.A]
			or player.inputs_pressed[player.Inputs.B]) \
			and attack_timer.is_stopped():
				player.use_attack(PlayerCharacter.Attack.EYE_BEAM)
				attack_timer.start(0.2)
		
		if player.inputs_pressed[player.Inputs.START]:
			player.use_attack(PlayerCharacter.Attack.WING_ATTACK)

			
	if parent.character == PlayerCharacter.Type.HEDORAH:
		if parent.move_state == PlayerCharacter.State.FLY\
		and parent.inputs_pressed[PlayerCharacter.Inputs.START]:
			parent.animation_player.play("TransformationOut")
			parent.animation_player.speed_scale =+ 1
			parent.get_sfx("HedorahMorphOut").play()
			parent.inputs[PlayerCharacter.Inputs.XINPUT] = 0
			parent.inputs[PlayerCharacter.Inputs.YINPUT] = 0
			parent.inputs_pressed[PlayerCharacter.Inputs.START] = false
			parent.has_input = false
			parent.move_speed = 1 * 60
			await parent.animation_player.animation_finished
			parent.has_input = true
			
			parent.move_state = PlayerCharacter.State.WALK
			parent.state.current = parent.move_state
			parent.animation_player.play("Walk") 
			parent.skin.get_node("Body/Head").visible = true

func move(delta: float) -> void:
	var xspeed: float = player.move_speed
	var ylimit := YLIMIT
	
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		ylimit += camera.limit_top
		if camera.is_camera_moving():
			xspeed = 1 * 60
		
	player.velocity.x = signf(player.inputs[player.Inputs.XINPUT]) * xspeed
	player.velocity.y = signf(player.inputs[player.Inputs.YINPUT]) * player.move_speed
	
	if player.allow_direction_changing and signf(player.inputs[player.Inputs.XINPUT]) != 0:
		player.direction = signf(player.inputs[player.Inputs.XINPUT])
	
	floor_checking.position.y = player.velocity.y * delta
	
	if Global.get_current_scene().has_node("HUD"):
		ylimit += Global.get_current_scene().get_node("HUD").vertical_size
	
	if floor_checking.has_overlapping_bodies() and player.velocity.y > 0:
		player.velocity.y = 0
	elif (player.position.y + player.velocity.y * delta) < ylimit \
		and player.velocity.y < 0:
		player.velocity.y = 0
		player.position.y = ylimit

func reset() -> void:
	player.animation_player.play("Idle")
