extends "res://Scripts/Objects/Characters/PlayerState.gd"

const BlobDrop := preload("res://Objects/Characters/BlobDrop.tscn")

const YLIMIT = 72
var floor_checking: Area2D
var attack_timer := Timer.new()
var timer := Timer.new()

func state_init() -> void:
	floor_checking = player.get_node("MothraFloorChecking")
	attack_timer.one_shot = true
	add_child(attack_timer)
	timer.one_shot = true
	add_child(timer)

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

			
	if player.character == PlayerCharacter.Type.HEDORAH:
		low_hp()
		if timer.is_stopped():
			var amount := 0.1 * 8
			if player.health.value < amount:
				return
			player.health.use(amount)
			
			var particle := BlobDrop.instantiate()
			Global.get_current_scene().add_child(particle)
			
			particle.setup(particle.Type.BLOB_DROP, player)
			particle.global_position = (
				player.global_position + Vector2(10 * player.direction, -2)
			)
			timer.start(0.4)
		if player.inputs_pressed[PlayerCharacter.Inputs.START]:
			player.skin.get_node("Body/Head").visible = false
			player.move_state = PlayerCharacter.State.WALK
			player.state.current = player.move_state
			player.get_sfx("HedorahMorphOut").play()
			player.animation_player.play("TransformationOut")
			player.animation_player.speed_scale =+ 1
			var had_input := player.has_input
			player.has_input = false
			player.inputs[PlayerCharacter.Inputs.XINPUT] = 0.0
			player.inputs[PlayerCharacter.Inputs.YINPUT] = 0.0
			player.inputs_pressed[PlayerCharacter.Inputs.START] = false
			player.move_speed = 1 * 60
			await get_tree().create_timer(0.5, false).timeout
			
			player.has_input = had_input
			player.animation_player.play("Walk") 
			player.skin.get_node("Body/Head").visible = true
			
		if (player.inputs_pressed[player.Inputs.A])\
			and attack_timer.is_stopped():
				player.use_attack(PlayerCharacter.Attack.LASERBEAM_FLY)
				attack_timer.start(0.2)
		if (player.inputs_pressed[player.Inputs.B])\
			and attack_timer.is_stopped():
				player.use_attack(PlayerCharacter.Attack.BLOB_BOMB)
				attack_timer.start(1)

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
	
func low_hp() -> void:
	if player.health.value <= 3 * 8:
		player.inputs_pressed[PlayerCharacter.Inputs.START] = true
