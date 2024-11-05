extends AnimatedSprite2D

enum Type {
	EYE_BEAM,
	WING,
}

@onready var timer := $Timer
@onready var animation_player := $AnimationPlayer
@onready var attack_component: AttackComponent = $AttackComponent

var velocity := Vector2()
var type: Type

func setup(init_type: Type, player: PlayerCharacter) -> void:
	type = init_type
	attack_component.objects_to_ignore.append(player)
	attack_component.enemy = player.attack.enemy
	attack_component.attacked.connect(player._on_attack_component_attacked)
	
	scale.x = player.direction
	match type:
		Type.EYE_BEAM:
			# Mind you that this refers to the "animation" property
			# of AnimatedSprite2D (the class that Mothra particles extend)
			# and not the animation of the AnimationPlayer
			animation = "EyeBeam"
			
			timer.start(0.3)
			timer.timeout.connect(func() -> void: queue_free())
			velocity = Vector2(5 * player.direction * 60, 0)
			
		Type.WING:
			animation = "Wing"
			animation_player.play("Flash")
			velocity = Vector2(randi_range(2, 10) * 0.1 * 60 * player.direction,
							randi_range(6, 9) * 0.1 * 60)
							
	attack_component.attacked.connect(func(_body: Node2D, _amount: float) -> void:
		queue_free()
		)
			
	attack_component.set_hitbox(
		sprite_frames.get_frame_texture(animation, 0).get_size(),
		Vector2.ZERO
		)

func _physics_process(delta: float) -> void:
	if type == Type.WING:
		velocity.y += 1 * 60 * delta
	position += velocity * delta
	var camera := get_viewport().get_camera_2d()
	var limit: float = Global.get_content_size().y + 20.0
	if camera != null:
		limit += camera.get_screen_center_position().y
	if position.y > limit:
		queue_free()
