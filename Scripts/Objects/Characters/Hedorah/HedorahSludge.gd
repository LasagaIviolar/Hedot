extends AnimatedSprite2D

enum Type {
	SLUDGE,
	SLUDGE_DOWN,
	BLOB_BOMB,
}

@onready var timer := $Timer
@onready var animation_player := $AnimationPlayer
@onready var player : Node2D = $Player
@onready var attack_component: Node2D = $AttackComponent

var velocity := Vector2()
var type: Type

@warning_ignore("shadowed_variable")
func setup(init_type: Type, player: PlayerCharacter) -> void:
	self.player = player
	type = init_type
	attack_component.objects_to_ignore.append(player)
	attack_component.enemy = player.attack.enemy
	attack_component.attacked.connect(player._on_attack_component_attacked)
	
	scale.x = player.direction
	match type:
		Type.SLUDGE:
			animation = "Sludge"
			animation_player.play("Sludge")
			timer.start(0.4)
			velocity = Vector2(randi_range(6, 8) * 0.085 * 60 * player.direction,
							randi_range(6, 9) * -0.1 * 60)
		Type.SLUDGE_DOWN:
			animation = "Sludge"
			animation_player.play("Sludge")
			timer.start(0.4)
			velocity = Vector2(randi_range(6, 8) * 0.08 * 60 * player.direction,
							randi_range(6, 9) * -0.001 * 60)
	attack_component.attacked.connect(func(_body: Node2D, _amount: float) -> void:
		velocity = Vector2.ZERO
		animation = "Sludge_Boom"
		animation_player.play("Sludge_Boom")
		await animation_player.animation_finished
		player.get_sfx("HedorahSludgeHit").play()
		attack_component.stop_attack()
		queue_free()
		)
	attack_component.set_collision(
		sprite_frames.get_frame_texture(animation, 0).get_size(),
		Vector2.ZERO
		)
		
func _physics_process(delta: float) -> void:
	if type == Type.SLUDGE:
		velocity.y += 1 * 60 * delta
	position += velocity * delta
	var camera := get_viewport().get_camera_2d()
	var limit: float = Global.get_content_size().y + 20.0
	if camera != null:
		limit += camera.get_screen_center_position().y
	if position.y > limit:
		queue_free()
	if type == Type.SLUDGE_DOWN:
		velocity.y += 1 * 60 * delta
	position += velocity * delta
	if camera != null:
		limit += camera.get_screen_center_position().y
	if position.y > limit:
		queue_free()
		
func _on_area_2d_body_entered(body: Node2D) -> void:
		if body != player:
			velocity = Vector2.ZERO
			animation = "Sludge_Boom"
			animation_player.play("Sludge_Boom")
			await animation_player.animation_finished
			player.get_sfx("HedorahSludgeHit").play()
			attack_component.stop_attack()
			queue_free()
