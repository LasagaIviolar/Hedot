extends AnimatedSprite2D

const EXPLOSION := preload("res://Objects/Levels/Explosion.tscn")
const BLOB_DROP := preload("res://Objects/Characters/BlobDrop.tscn")

enum Type {
	BLOB_BOMB,
}
@warning_ignore("unused_parameter")
@onready var timer := $Timer
@onready var animation_player := $AnimationPlayer
@onready var player : Node2D = $Player
@onready var attack_component: Node2D = $AttackComponent
@onready var attack_component2: Node2D = $AttackComponent2

var velocity := Vector2()
var type: Type

@warning_ignore("shadowed_variable")
func setup(init_type: Type, player: PlayerCharacter) -> void:
	self.player = player
	type = init_type
	attack_component.objects_to_ignore.append(player)
	attack_component.enemy = player.attack.enemy
	attack_component.attacked.connect(player._on_attack_component_attacked)
	attack_component2.objects_to_ignore.append(player)
	attack_component2.enemy = player.attack.enemy
	attack_component2.attacked.connect(player._on_attack_component_attacked)
	
	scale.x = player.direction
	match type:
		Type.BLOB_BOMB:
			animation = "Blob_Bomb"
			animation_player.play("Blob_Bomb")
			velocity = Vector2(0, -100.25)
	attack_component2.attacked.connect(func(_body: Node2D, _amount: float) -> void:
		attack_component2.stop_attack()
		attack_component.set_collision(Vector2(32,32), Vector2(0, 0))
		velocity = Vector2.ZERO
		var explosion := EXPLOSION.instantiate()
		explosion.global_position = global_position
		get_parent().add_child(explosion)
		for i in range(10):
			var blob_drop := BLOB_DROP.instantiate()
			Global.get_current_scene().add_child(blob_drop)
			blob_drop.setup(blob_drop.Type.BLOB_DROP, player)
			blob_drop.global_position = (global_position + Vector2(0, -24)
			)
			blob_drop.velocity = Vector2(randi_range(-30.5, 36) * -0.085 * 60,
							randi_range(1.25, 36) * -0.085 * 60)
		player.get_sfx("HedorahBlobBomb").play()
		animation = "Sludge_Boom"
		animation_player.play("Sludge_Boom")
		await animation_player.animation_finished
		queue_free()
		)
	attack_component2.set_collision(Vector2(8,16), Vector2(0, 0))
	
func _physics_process(delta: float) -> void:
	if type == Type.BLOB_BOMB:
		velocity.y += 1 * 60 * 7.5 * delta
	position += velocity * delta

func _on_area_2d_body_entered(body: Node2D) -> void:
	attack_component2.stop_attack()
	attack_component.set_collision(Vector2(32,32), Vector2(0, 0))
	velocity = Vector2.ZERO
	var explosion := EXPLOSION.instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	for i in range(10):
		var blob_drop := BLOB_DROP.instantiate()
		Global.get_current_scene().add_child(blob_drop)
		blob_drop.setup(blob_drop.Type.BLOB_DROP, player)
		blob_drop.global_position = (global_position + Vector2(0, -4)
		)
		blob_drop.velocity = Vector2(randi_range(-30.5, 36) * -0.085 * 60,
							randi_range(1.25, 36) * -0.085 * 60)
	player.get_sfx("HedorahBlobBomb").play()
	animation = "Sludge_Boom"
	animation_player.play("Sludge_Boom")
	await animation_player.animation_finished
	queue_free()
