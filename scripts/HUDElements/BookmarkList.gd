@icon("res://sprites/script_icons/list.svg")

extends Panel

@onready var tp : Vector2 # Target Position
@onready var init_p : Vector2
@onready var close_p : Vector2

var opened : bool = false

########################################### OVERRIDES
func _____OVERRIDES(): pass


func _ready():
	init_p = position
	close_p = Vector2(get_viewport().size.x, init_p.y)
	tp = close_p

func _process(_delta):
	position += (tp - position) * .33
	
	tp = init_p if opened else close_p



########################################### HELPER FUNCTIONS
func _____HELPERS(): pass



########################################### SIGNALS
func _____SIGNALS(): pass


func _on_bookmark_list_button_pressed():
	opened = !opened
