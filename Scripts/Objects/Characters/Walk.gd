extends State

const YLIMIT = 72
var floor_checking: Area2D

@onready var collision: CollisionShape2D = $Collision
# Move state is used for characters that walk on the ground.
# This state consists of not only walking but also crouching and jumping.
# This state also includes the movement for flying characters.

var walk_frame := 0.0
var walk_frames := 0
var walk_frame_speed := 0

var jumping := false
var jump_speed := -2 * 60

func state_init() -> void:
	if not parent.is_flying():
		walk_frames = parent.body.sprite_frames.get_frame_count("Walk")
	
	match parent.character:
		PlayerCharacter.Type.GODZILLA:
			walk_frame_speed = 9
		PlayerCharacter.Type.HEDORAH:
			walk_frame_speed = 5
			# # You can change the jumping speed for your character like this
			# jump_speed = -1 * 60

func _process(delta: float) -> void:
	move(delta)
	
	# Attacks
	match parent.character:
		PlayerCharacter.Type.GODZILLA:
			common_ground_attacks()
			if parent.animation_player.current_animation == "Crouch" \
				and parent.inputs_pressed[PlayerCharacter.Inputs.B]:
					parent.use_attack(PlayerCharacter.Attack.TAIL_WHIP)
			if parent.inputs_pressed[PlayerCharacter.Inputs.START] \
				and parent.power.value >= 6 * 8:
				parent.use_attack(PlayerCharacter.Attack.HEAT_BEAM)
		
		PlayerCharacter.Type.HEDORAH:
			if parent.inputs_pressed[PlayerCharacter.Inputs.A]:
				parent.use_attack(PlayerCharacter.Attack.HEDORAH_PUNCH)
			if parent.inputs[PlayerCharacter.Inputs.YINPUT] <= 0 \
				and parent.inputs_pressed[PlayerCharacter.Inputs.B]:
				parent.use_attack(PlayerCharacter.Attack.SLUDGE)
			if parent.inputs[PlayerCharacter.Inputs.YINPUT] > 0 \
				and parent.inputs_pressed[PlayerCharacter.Inputs.B]:
				parent.use_attack(PlayerCharacter.Attack.SLUDGE_DOWN)
			if parent.move_state == PlayerCharacter.State.WALK\
				and parent.inputs_pressed[PlayerCharacter.Inputs.START]:
				parent.animation_player.play("TransformationIn")
				parent.get_sfx("HedorahMorph").play()
				print(1)
				parent.animation_player.speed_scale =+ 1
				parent.inputs[PlayerCharacter.Inputs.XINPUT] = 0
				parent.inputs[PlayerCharacter.Inputs.YINPUT] = 0
				parent.inputs_pressed[PlayerCharacter.Inputs.START] = false
				parent.has_input = false
				parent.velocity.y = 0
				var gravity_saved = parent.gravity
				parent.gravity = 0
				parent.set_collision(Vector2(48, 24), Vector2(-4, 1))
				parent.move_speed = 2 * 60
				parent.collision.position = Vector2(0, 0)
				await parent.animation_player.animation_finished
				parent.has_input = true
				parent.gravity += gravity_saved
				
				parent.move_state = PlayerCharacter.State.FLY
				parent.state.current = parent.move_state
				parent.animation_player.play("Idle") 
				

				
func common_ground_attacks() -> void:
	if parent.inputs_pressed[PlayerCharacter.Inputs.A]:
		parent.use_attack(PlayerCharacter.Attack.PUNCH)
	if parent.animation_player.current_animation != "Crouch" \
		and parent.inputs_pressed[PlayerCharacter.Inputs.B]:
			parent.use_attack(PlayerCharacter.Attack.KICK)

func move(delta: float) -> void:
	var dirx: float = signf(parent.inputs[PlayerCharacter.Inputs.XINPUT])
	if dirx:
		parent.velocity.x = parent.move_speed * dirx
		
		if parent.allow_direction_changing:
			parent.direction = int(signf(dirx))
			
		walk_frame = wrapf(
			walk_frame + walk_frame_speed * delta * dirx * parent.direction,
			0, walk_frames)
			
		if parent.body.animation == "Walk":
			parent.body.frame = int(walk_frame)
	else:
		parent.velocity.x = 0
		
	var diry: float = parent.inputs[PlayerCharacter.Inputs.YINPUT]
	
	# Jump!
	if parent.is_on_floor() and diry < -0.4:
		parent.velocity.y = jump_speed
		jumping = true
	
	# Variable jump height
	if not parent.is_on_floor() and jumping:
		if diry < -0.4 and parent.velocity.y < -1.95 * 60:
			parent.velocity.y -= 216 * delta
		if parent.velocity.y < 0 and diry >= -0.4:
			jumping = false
			parent.velocity.y = 0
	
	# Crouch
	if diry > 0.4 and parent.body.sprite_frames.has_animation("Crouch"):
		if parent.animation_player.current_animation == "Walk"\
			or parent.animation_player.current_animation == "":
			parent.animation_player.play("Crouch")

	if diry <= 0.4 and parent.animation_player.current_animation == "Crouch":
		parent.animation_player.play("RESET")

func reset() -> void:
	walk_frame = 0
