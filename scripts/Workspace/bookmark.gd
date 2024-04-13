class_name Bookmark
extends TextureRect

@onready var bm_name_panel = $PanelContainer
@onready var bm_name_label = $PanelContainer/BookmarkNameLabel

var offset : Vector2 = Vector2.ZERO
var dragging : bool = false
@onready var bm_name : String = "Bookmark" :
	get:
		return bm_name
	set(_value):
		bm_name = _value
		bm_name_label.text = _value

########################################### OVERRIDES
func _____OVERRIDES(): pass


func _ready():
	pass

func _process(_delta):
	if dragging:
		global_position = get_global_mouse_position() + offset



########################################### HELPER FUNCTIONS
func _____HELPERS(): pass


func help():
	pass



########################################### SIGNALS
func _____SIGNALS(): pass


func _on_child_key_pressed():
	pass


func _on_gui_input(event):	
	if event.is_action_pressed("lmb"):
		dragging = true
		offset = global_position - get_global_mouse_position()
	elif event.is_action_released("lmb"):
		dragging = false
	
	if event.is_action_pressed("rmb"):
		queue_free()

func _on_mouse_entered():
	bm_name_panel.visible = true
func _on_mouse_exited():
	bm_name_panel.visible = false
