extends Node2D

@onready var parent: PlayerCharacter = get_parent()
@onready var body := $Body
@onready var head := $Body/Head

func _process(_delta: float) -> void:
	if body.animation == "Walk" and head.animation == "Walk":
			head.frame = body.frame
