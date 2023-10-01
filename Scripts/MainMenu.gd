extends Node2D

var current_menu: Node2D

@onready var selector: ColorRect = $Selector
var selector_option := 0

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
		
	current_menu = $MenuMain
	move_selector(0)
	enable_menu(current_menu, true)
	
	Global.play_music(preload("res://Audio/Soundtrack/MainMenu.ogg"))
	
func _process(delta: float) -> void:
	if selector.visible:
		if Input.is_action_just_pressed("Down"):
			selector_option += 1
			if selector_option >= current_menu.options.size():
				selector_option = 0
			move_selector(selector_option)
			
		if Input.is_action_just_pressed("Up"):
			selector_option -= 1
			if selector_option < 0:
				selector_option = current_menu.options.size() - 1
			move_selector(selector_option)
		
	if Input.is_action_just_pressed("B") \
		or Input.is_action_just_pressed("A") \
		or Input.is_action_just_pressed("Start"):
			current_menu.menu_select(selector_option)
			
	current_menu.menu_process(delta)
	
func enable_menu(menu: Node2D, flag: bool) -> void:
	menu.visible = flag
	menu.set_process(flag)
	menu.set_physics_process(flag)
	menu.set_process_input(flag)

func set_menu(menu: Node2D) -> void:
	enable_menu(current_menu, false)
	current_menu = menu
	enable_menu(current_menu, true)
	
	if current_menu.options.size() > 0:
		selector.visible = true
		selector_option = 0
		move_selector(0)
	else:
		# Hide the selector in case if the menu doesn't have options 
		selector.visible = false
	
func get_current_options() -> Array[Control]:
	var options: Array[Control] = []
	for c in current_menu.get_children():
		if c.name.begins_with("Opt"):
			options.append(c)
	return options
	
func move_selector(option: int) -> void:		
	var control_option = current_menu.options[option]
	selector.global_position = control_option.global_position + Vector2(-16, 0)