extends AnimatedSprite2D

enum Type {
	LASER,
	LASER_DOWN,
}

@onready var timer := $Timer
@onready var animation_player := $AnimationPlayer
@onready var attack_component: Node2D = $AttackComponent

var velocity := Vector2()
var type: Type

@warning_ignore("shadowed_variable")
func setup(init_type: Type, player: PlayerCharacter) -> void:
	type = init_type
	attack_component.objects_to_ignore.append(player)
	attack_component.enemy = player.attack.enemy
	attack_component.attacked.connect(player._on_attack_component_attacked)
	
	scale.x = player.direction
	match type:
		Type.LASER:
			animation = "LASER"
			animation_player.play("LASER")
			timer.start(0.4)
			velocity = Vector2(randi_range(3, 3) * 1 * 60 * player.direction,
							randi_range(3, 3) * 0 * 60)
		Type.LASER_DOWN:
			animation = "LASER_DOWN"
			animation_player.play("LASER_DOWN")
			timer.start(0.4)
			velocity = Vector2(randi_range(6, 6) * 0.3 * 60 * player.direction,
							randi_range(6, 6) *  0.25 * 60)
	attack_component.attacked.connect(func(_body: Node2D, _amount: float) -> void:
		queue_free()
		)
	attack_component.set_collision(
		sprite_frames.get_frame_texture(animation, 0).get_size(),
		Vector2.ZERO
		)

func _physics_process(delta: float) -> void:
	position += velocity * delta
	var camera := get_viewport().get_camera_2d()
	var limit: float = Global.get_content_size().y + 20.0
	if camera != null:
		limit += camera.get_screen_center_position().y
	if position.y > limit:
		queue_free()
