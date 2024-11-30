extends "res://Scripts/Objects/Characters/PlayerState.gd"

@onready var timer := Timer.new()
var hurt_time := 0.0
var move_state: Node

var flash_player: AnimationPlayer

func state_init() -> void:
	move_state = player.state.states_list[player.move_state]
	timer.timeout.connect(_on_timeout)
	timer.one_shot = true
	add_child(timer)
	flash_player = player.skin.get_node("FlashPlayer")

func state_entered() -> void:
	if player.is_flying():
		player.velocity = Vector2()
	# -1 if facing right and 1 if facing left
	player.velocity.x = -player.direction * player.move_speed
	player.play_sfx("Hurt")
	timer.start(hurt_time)
	
	move_state = parent.state.states_list[parent.move_state]
	
	if parent.character != PlayerCharacter.Type.HEDORAH:
		if player.animation_player.has_animation("Hurt"):
			player.animation_player.play("RESET")
			await get_tree().process_frame
			player.animation_player.play("Hurt")
	if parent.character == PlayerCharacter.Type.HEDORAH:
		player.animation_player.play("RESET")
		await get_tree().process_frame
		flash_player.play("Hurt") 
		parent.state.current = parent.move_state
		if parent.move_state == PlayerCharacter.State.FLY:
			flash_player.play("Hurt")
			parent.animation_player.play("Idle")
			parent.state.current = parent.move_state
			parent.move_state = PlayerCharacter.State.FLY
	if parent.character == PlayerCharacter.Type.GIGAN:
		flash_player.play("Hurt") 
		await player.animation_player.animation_finished
		parent.state.current = parent.move_state

func _on_timeout() -> void:
	# Might be called after the character died
	if player.state.current != PlayerCharacter.State.HURT:
		return
	player.animation_player.play("RESET")
	move_state.reset()
	player.state.current = player.move_state
