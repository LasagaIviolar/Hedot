@tool
class_name BoardPiece
extends Sprite2D

const PIECE_STEPS := [
	2, # Godzilla
	4, # Mothra
	2, # Hedorah
	2, # Gigan
]
const FRAME_COUNT := 3  # White piece and 2 colored walking sprites
const FRAME_SPEED := [
	0.13, # Godzilla
	0.2, # Mothra
	0.13, # Hedorah
	0.13, # Gigan
]

@export var piece_character := PlayerCharacter.Type.GODZILLA:
	set(value):
		piece_character = value
		update_frame()
		queue_redraw()
@export_enum("Player", "Boss") var piece_type := 0:
	set(value):
		piece_type = value
		update_frame()
		queue_redraw()
@export var boss_scene: PackedScene = null
## Only works if it's a boss, otherwise loaded from the current save.
## If there's no current save, then it's 1.
@export var level := 1

# "Board Pieces" node
@onready var parent := get_parent()

var tilemap: TileMapLayer
var selector: BoardSelector
var board: Board

var init_pos: Vector2
var piece_frame := 0
var tile_below := Vector2i(-1, -1)
var scene_tile_below: LevelSceneTile
var selected := false
var steps := 0
var walk_frame := 0.0
var walk_anim := 0

class CharacterData:
	var hp := 0.0
	var bars := 0
	var xp := 0
	var level := 1

var character_data := CharacterData.new()

func _ready() -> void:
	# Remember that this script is a tool script and can run in Godot editor
	if Engine.is_editor_hint():
		return
	
	await Global.get_current_scene().ready
	update_frame()
	selector = Global.board.selector if is_instance_valid(Global.board) else null
	if selector == null:
		return
	tilemap = selector.tilemap
	board = Global.board
	process_priority = 1
	
	# Adjust position
	position = selector.map_to_tilemap(position, tilemap)
	init_pos = position
	
	await get_tree().process_frame
	hide_cell_below()
	
	if piece_character == PlayerCharacter.Type.MOTHRA:
		walk_anim = 1
	
	var players_data: Dictionary = Global.board.board_data["players"]
	if players_data.has(name):
		character_data.level = players_data[name]["level"]
		character_data.xp = players_data[name]["xp"]
		level = character_data.level
		
	steps = PIECE_STEPS[piece_character]
	character_data.bars = PlayerCharacter.calculate_bar_count(piece_character, level)
	character_data.hp = character_data.bars * 8

func _process(delta: float) -> void:
	if selected and is_instance_valid(selector):
		global_position = selector.global_position
		
		if walk_anim == 0 and not selector.is_stopped() \
			or walk_anim == 1:
				# Switch frame every 0.2 of a second
				walk_frame += delta / FRAME_SPEED[piece_character]
				if walk_frame >= 2:
					walk_frame -= 2
				piece_frame = floori(1 + walk_frame)
				update_frame()

func update_frame() -> void:
	# + 1 to skip the top row of the spritesheet (non-character sprites for boards)
	var xoffset := 48 * piece_frame
	var yoffset := 48 * (piece_character + 1)
	
	region_rect.position.x = xoffset
	region_rect.position.y = yoffset
	
	# Face the left direction if it's a boss
	scale.x = 1 if piece_type == 0 else -1

func get_cell_pos() -> Vector2i:
	if Engine.is_editor_hint():
		return Vector2i.ZERO
	return selector.get_cell_pos(position)

func hide_cell_below() -> void:
	if Engine.is_editor_hint():
		return
		
	# Check if there's a scene tile below
	scene_tile_below = board.get_current_scene_tile(get_cell_pos())
	if scene_tile_below != null:
		scene_tile_below.hide()
		return
		
	var tile: Vector2i = selector.cell_from_pos(get_cell_pos())
	if tile.x < 0: # Return if already hidden
		return
	tile_below = tile
	tilemap.erase_cell(get_cell_pos())
	
func show_cell_below() -> void:
	if scene_tile_below != null:
		scene_tile_below.show()
		return
	
	tilemap.set_cell(get_cell_pos(), 1, tile_below)
	tile_below = Vector2i(-1, -1)

# The player/boss has selected this board piece
func select() -> void:
	selected = true
	
	piece_frame = 1
	walk_frame = 0.0
	update_frame()
	
	if is_instance_valid(Global.board):
		selector.visible = false
		# Just in case, but mostly for bosses
		selector.global_position = global_position
		show_cell_below()
		# Move this piece above every other piece
		parent.move_child(self, -1)
	
		Global.play_global_sfx("MenuBip")
	
func deselect() -> void:
	selected = false
	
	piece_frame = 0
	update_frame()
	
	if is_instance_valid(Global.board):
		selector.visible = true
		selector.reset_playing_levels()
		
		position = init_pos
		hide_cell_below()
	
func prepare_start() -> void:
	init_pos = position
	selected = false
	
	piece_frame = 0
	update_frame()
	
	hide_cell_below()
	
func remove() -> void:
	if is_instance_valid(Global.board) and Global.board.selected_piece == self:
		Global.board.selected_piece = null
	selector.visible = true
	show_cell_below()
	queue_free()
	
func save_data() -> void:
	if not is_instance_valid(Global.board):
		return
		
	var board_data := Global.board.board_data
	if not board_data["players"].has(name):
		board_data["players"][name] = {}
	board_data["players"][name]["level"] = character_data.level
	board_data["players"][name]["xp"] = character_data.xp
	
func is_player() -> bool:
	return piece_type == 0
	
func get_nav_agent() -> NavigationAgent2D:
	return $NavigationAgent2D
	
func get_character_name() -> String:
	return PlayerCharacter.get_character_name_static(piece_character)
