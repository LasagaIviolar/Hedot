extends AnimatedSprite2D

enum Type {
	LASERBEAM_FLY
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
		Type.LASERBEAM_FLY:
			animation = "HedriumRayFly"
			animation_player.play("Hedrium_Ray_Fly")
			timer.start(0.3)
			timer.timeout.connect(func() -> void: queue_free())
			velocity = Vector2(5 * player.direction * 60, 0)
			
	attack_component.set_collision(
		sprite_frames.get_frame_texture(animation, 2).get_size(),
		Vector2.ZERO
		)
