extends "res://Scripts/Objects/Characters/PlayerState.gd"

const Laser := preload("res://Objects/Characters/Laser.tscn")
const HedorahRay := preload("res://Objects/Characters/HedorahRay.tscn")
const HedorahSludge := preload("res://Objects/Characters/HedorahSludge.tscn")
const BlobBomb := preload("res://Objects/Characters/BlobBomb.tscn")
const MothraParticle := preload("res://Objects/Characters/MothraParticle.tscn")
const GodzillaHeatBeam := preload("res://Objects/Characters/GodzillaHeatBeam.tscn")

var move_state: Node
var current_attack: PlayerCharacter.Attack
var variation := 0

var attack_component: AttackComponent

var flash_player: AnimationPlayer

func state_init() -> void:
	attack_component = player.attack
	move_state = player.state.states_list[player.move_state]
	player.animation_player.animation_finished.connect(_on_animation_finished)
	flash_player = player.skin.get_node("FlashPlayer")
	
var save_allow_direction_changing := false
func state_entered() -> void:
	save_allow_direction_changing = player.allow_direction_changing
	player.allow_direction_changing = false
	
func state_exited() -> void:
	player.allow_direction_changing = save_allow_direction_changing
	attack_component.stop_attack()
	
func is_still_attacking() -> bool:
	return player.state.current == PlayerCharacter.State.ATTACK

func _process(delta: float) -> void:
	# Allow the player to move while attacking
	move_state.move(delta)

func use(type: PlayerCharacter.Attack) -> void:
	player.state.current = PlayerCharacter.State.ATTACK
	current_attack = type
	
	match type:
		PlayerCharacter.Attack.PUNCH, PlayerCharacter.Attack.KICK:
			player.animation_player.play("RESET")
			await get_tree().process_frame
	
	match type:
		# Common ground attacks
		PlayerCharacter.Attack.PUNCH:
			variation = not variation
			player.animation_player.play("Punch1" if variation else "Punch2")
			player.play_sfx("Punch")
			
			attack_component.set_hitbox_template("Punch")
			attack_component.global_position = (
				player.global_position + Vector2(20 * player.direction, -20)
			)
			
			attack_component.start_attack(2)
			await player.animation_player.animation_finished
			attack_component.stop_attack()

		PlayerCharacter.Attack.KICK:
			variation = not variation
			player.animation_player.play("Kick1" if variation else "Kick2")
			player.play_sfx("Punch")
			
			attack_component.set_hitbox_template("Kick")
			attack_component.global_position = (
				player.global_position + Vector2(20 * player.direction, 12)
			)
			
			attack_component.start_attack(2)
			await player.animation_player.animation_finished
			attack_component.stop_attack()
			
		# Godzilla-specific attacks
		PlayerCharacter.Attack.TAIL_WHIP:
			player.play_sfx("GodzillaTailWhip")
			player.animation_player.play("TailWhip")
			await get_tree().create_timer(0.15, false).timeout
			if not is_still_attacking(): return
			
			attack_component.set_hitbox_template("TailWhip")
			attack_component.global_position = (
				player.global_position + Vector2(30 * player.direction, 5.5)
			)
			
			attack_component.start_attack(2)
			await player.animation_player.animation_finished
			attack_component.stop_attack()
			
		PlayerCharacter.Attack.HEAT_BEAM:
			var animations := [
				["HeatBeam1", 0.1],
				["HeatBeam2", 1],
				["HeatBeam1", 0.1],
				["HeatBeam3", 1],
			]
			
			for anim: Array in animations:
				player.animation_player.play(anim[0] as String)
				
				if anim[0] == "HeatBeam3":
					create_heat_beam()
					player.play_sfx("HeatBeam")
					
				await get_tree().create_timer(anim[1], false).timeout
				if not is_still_attacking(): return
				
			move_state.walk_frame = 0
			player.animation_player.play("RESET")
			player.state.current = player.move_state
			
		# Mothra-specific attacks
		PlayerCharacter.Attack.EYE_BEAM:
			flash_player.play("EyeBeam")
			
			var particle := MothraParticle.instantiate()
			Global.get_current_scene().add_child(particle)
			
			particle.setup(particle.Type.EYE_BEAM, player)
			particle.global_position = (
				player.global_position + Vector2(20 * player.direction, -2)
			)
			
			player.state.current = player.move_state
			player.play_sfx("Step")
			attack_component.start_attack(2)
			await player.animation_player.animation_finished
			attack_component.stop_attack()
			
		PlayerCharacter.Attack.WING_ATTACK:
			player.animation_player.play("Wing")
			player.animation_player.speed_scale = 2
			
			# Calculate the amount of power this attack should use
			var power := mini(player.power.value, 2 * 8)
			
			# Calculate the number of wing particles that should be created
			var times := int(power / 2.6)
			
			# Not enough power for this attack
			if times == 0:
				player.state.current = player.move_state
				return
				
			player.power.use(power)
			
			wing_attack_sfx(mini(3, times))
			
			for i in times:
				var particle := MothraParticle.instantiate()
				Global.get_current_scene().add_child(particle)
				
				particle.setup(particle.Type.WING, player)
				particle.global_position = player.global_position
				
				await get_tree().create_timer(0.15, false).timeout
				if not is_still_attacking(): return
				
			player.animation_player.speed_scale = 1
			player.animation_player.play("Idle")
			player.state.current = player.move_state
				
		# Hedorah-specific attacks
		PlayerCharacter.Attack.HEDORAH_PUNCH:
			variation = not variation
			player.animation_player.play("Punch1" if variation else "Punch2")
			player.play_sfx("HedorahPunch")
			
			attack_component.set_hitbox_template("Punch")
			attack_component.global_position = (
				player.global_position + Vector2(20 * player.direction, -2)
			)
			attack_component.global_rotation = (
				player.global_rotation + float(0 * player.direction)
			)
			
			attack_component.start_attack(2)
			await player.animation_player.animation_finished
			attack_component.stop_attack()
			
		PlayerCharacter.Attack.LASERBEAM_FLY:
			flash_player.play("Eye_Light")
			var particle := HedorahRay.instantiate()
			Global.get_current_scene().add_child(particle)
			
			
			particle.setup(particle.Type.LASERBEAM_FLY, player)
			particle.position = Vector2(26, 0) + Vector2(8, 0)
			particle.position.x *= player.direction
			particle.scale.x = player.direction
			particle.global_position = (
				player.global_position + Vector2(60 * player.direction, -5)
			)
			
			player.state.current = player.move_state
			player.play_sfx("HedorahLaserFly")
			attack_component.start_attack(2)
			await player.animation_player.animation_finished
			attack_component.stop_attack()
			
		PlayerCharacter.Attack.BLOB_BOMB:
			var amount := 1 * 8
			if player.health.value < amount:
				return
			player.health.use(amount)
			
			var particle := BlobBomb.instantiate()
			Global.get_current_scene().add_child(particle)
			
			particle.setup(particle.Type.BLOB_BOMB, player)
			particle.global_position = (
				player.global_position + Vector2(10 * player.direction, -2)
			)
			await get_tree().create_timer(0.15, false).timeout
			if not is_still_attacking(): return
			
			player.state.current = player.move_state
			
		PlayerCharacter.Attack.SLUDGE:
			# Calculate the amount of power this attack should use
			var power := mini(parent.power.value, 2 * 8)
			
			# Calculate the number of wing particles that should be created
			var times := int(power / 2.6)
			
			# Not enough power for this attack
			if times == 0:
				parent.state.current = parent.move_state
				return
				
			parent.power.use(power)
			
			for i in times:
				var particle := HedorahSludge.instantiate()
				Global.get_current_scene().add_child(particle)
				
				particle.setup(particle.Type.SLUDGE, parent)
				particle.global_position = (
				parent.global_position + Vector2(12 * parent.direction, -24)
			)
				
				await get_tree().create_timer(0.15, false).timeout
				if not is_still_attacking(): return
				
			parent.state.current = parent.move_state
			
		PlayerCharacter.Attack.SLUDGE_DOWN:
			# Calculate the amount of power this attack should use
			var power := mini(parent.power.value, 2 * 8)
			
			# Calculate the number of wing particles that should be created
			var times := int(power / 2.6)
			
			# Not enough power for this attack
			if times == 0:
				parent.state.current = parent.move_state
				return
				
			parent.power.use(power)
			
			for i in times:
				var particle := HedorahSludge.instantiate()
				Global.get_current_scene().add_child(particle)
				
				particle.setup(particle.Type.SLUDGE_DOWN, parent)
				particle.global_position = (
				parent.global_position + Vector2(12 * parent.direction, -24)
			)
				
				await get_tree().create_timer(0.15, false).timeout
				if not is_still_attacking(): return
				
			parent.state.current = parent.move_state
			
		PlayerCharacter.Attack.LASERBEAM:
			var amount := 6 * 8
			if player.power.value < amount:
				return
			player.power.use(amount)
			
			player.animation_player.play("Hedrium_Ray")
			player.play_sfx("HedorahLaser")
			
			attack_component.start_attack(5.5)
			attack_component.set_hitbox_template("Laser0")
			attack_component.global_position = (
				player.global_position + Vector2(34 * player.direction, 7)
			)
			attack_component.global_rotation = (
				player.global_rotation + float(61 * player.direction)
			)
			await get_tree().create_timer(1, false).timeout
			attack_component.start_attack(5.5)
			attack_component.set_hitbox_template("Laser1")
			attack_component.global_position = (
				player.global_position + Vector2(56 * player.direction, 3)
			)
			attack_component.global_rotation = (
				player.global_rotation + float(-15 * player.direction)
			)
			await get_tree().create_timer(0.25, false).timeout
			attack_component.start_attack(6)
			attack_component.set_hitbox_template("Laser2")
			attack_component.global_position = (
				player.global_position + Vector2(64 * player.direction, -18)
			)
			attack_component.global_rotation = (
				player.global_rotation + float(0 * player.direction)
			)
			await get_tree().create_timer(0.25, false).timeout
			attack_component.start_attack(6)
			attack_component.set_hitbox_template("Laser3")
			attack_component.global_position = (
				player.global_position + Vector2(56 * player.direction, -51)
			)
			attack_component.global_rotation = (
				player.global_rotation + float(-32 * player.direction)
			)
			await get_tree().create_timer(0.25, false).timeout
			
			await player.animation_player.animation_finished
			attack_component.stop_attack()
			
			player.animation_player.play("RESET")
			player.state.current = PlayerCharacter.State.WALK
			
		# Gigan-specific attacks
		PlayerCharacter.Attack.LASER:
			var amount := 2.5 * 8
			if player.power.value < amount:
				return
			player.power.use(amount)
			
			for i in range(5):
				var particle := Laser.instantiate()
				Global.get_current_scene().add_child(particle)
				
				particle.setup(particle.Type.LASER, parent)
				particle.global_position = (
				parent.global_position + Vector2(12 * parent.direction, -35)
			)
				
				await get_tree().create_timer(0.15, false).timeout
				if not is_still_attacking(): return
				
			parent.state.current = parent.move_state
			
		PlayerCharacter.Attack.LASER_DOWN:
			var amount := 2.5 * 8
			if player.power.value < amount:
				return
			player.power.use(amount)
			
			for i in range(7):
				var particle := Laser.instantiate()
				Global.get_current_scene().add_child(particle)
				
				particle.setup(particle.Type.LASER_DOWN, parent)
				particle.global_position = (
				parent.global_position + Vector2(12 * parent.direction, -35)
			)
				
				await get_tree().create_timer(0.15, false).timeout
				if not is_still_attacking(): return
				
			parent.state.current = parent.move_state
			
func create_heat_beam() -> void:
	const HEAT_BEAM_COUNT := 12
	var heat_beams: Array[AnimatedSprite2D] = []
	player.power.use(6 * 8)
	
	for i in HEAT_BEAM_COUNT:
		var particle := GodzillaHeatBeam.instantiate()
		
		particle.setup(i, player)
		particle.position = Vector2(26, 0) + Vector2(8, 0) * i
		particle.position.x *= player.direction
		particle.scale.x = player.direction
		particle.particle_array = heat_beams
		
		player.add_child(particle)
		heat_beams.append(particle)
		
	for i in HEAT_BEAM_COUNT:
		heat_beams[i].start()
		await get_tree().create_timer(0.01, false).timeout
		
func wing_attack_sfx(times: int) -> void:
	for i in times:
		player.play_sfx("Wing")
		await get_tree().create_timer(0.25, false).timeout

func _on_animation_finished(anim_name: String) -> void:
	if not is_still_attacking(): return
	match anim_name:
		"Punch1", "Punch2":
			player.animation_player.play("RESET")
			player.state.current = PlayerCharacter.State.WALK
		"Kick1", "Kick2":
			move_state.walk_frame = 0
			player.animation_player.play("RESET")
			player.state.current = PlayerCharacter.State.WALK
		"TailWhip":
			move_state.walk_frame = 0
			if player.inputs[PlayerCharacter.Inputs.YINPUT] > 0:
				player.animation_player.play("Crouch")
			else:
				player.animation_player.play("RESET")
			player.state.current = PlayerCharacter.State.WALK
		"EyeBeam":
			player.animation_player.play("RESET")
			player.state.current = PlayerCharacter.State.FLY
		"HedriumRayFly":
			player.animation_player.play("Idle")
			player.state.current = PlayerCharacter.State.FLY
