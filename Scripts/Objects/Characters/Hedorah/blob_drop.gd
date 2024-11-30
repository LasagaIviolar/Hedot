extends AnimatedSprite2D

enum Type {
	BLOB_DROP,
}

@onready var timer := $Timer
@onready var animation_player := $AnimationPlayer
@onready var player: PlayerCharacter
@onready var area_2d: Area2D = $Area2D
@onready var sfx: AudioStreamPlayer = $SFX

var velocity := Vector2()
var is_on_floor = false
var magnetic = false
var type: Type

@warning_ignore("shadowed_variable")
func setup(init_type: Type, player: PlayerCharacter) -> void:
	self.player = player
	type = init_type
	scale.x = player.direction
	
	match type:
		Type.BLOB_DROP:
			animation = "Blob_Drop"
			animation_player.play("Blob_Drop")
	
func _physics_process(delta: float) -> void:
	if is_on_floor:
		velocity = Vector2.ZERO
	else:
		velocity.y += 1 * 60 * 7.5 * delta
	position += velocity * delta
	if magnetic:
		magnet_blobs(player)
		velocity = Vector2.ZERO

@warning_ignore("unused_parameter")
func _on_area_2d_body_entered(body: Node2D) -> void:
	is_on_floor = true
	magnetic = true
	animation_player.play("BlobDropGround")
	await get_tree().create_timer(8, false).timeout
	animation_player.play("BlobDropDead")
	await animation_player.animation_finished
	queue_free()
	
@warning_ignore("shadowed_variable")
func magnet_blobs(player: PlayerCharacter) -> void:
	if player.move_state == PlayerCharacter.State.WALK\
		and magnetic == true:
		is_on_floor = false
		var a = 0.1
		var b = 0
		var DestX = player.position.x
		var DestY = player.position.y
		position.x += (-a * (position.x - DestX)) + (b * (position.y - DestY))
		position.y += (-b * (position.x - DestX)) - (a * (position.y - DestY))
		animation_player.play("BlobDropMagnet")
		await player.animation_player.animation_finished
		destroy(player)
	if player.move_state == PlayerCharacter.State.FLY:
		magnetic == false

func destroy(character: PlayerCharacter) -> void:
	if timer.is_stopped():
		player.play_sfx("HedorahBlobMerge")
		
		player.health.heal(0.105 * 8)
		queue_free()
		timer.start(0.4)
