@icon("res://sprites/script_icons/bookmark.svg")

class_name Bookmark
extends TextureRect

signal NameChangeRequested
signal NameChanged#MAYBE (_old_name : String, _new_name : String)

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
		emit_signal("NameChanged")#MAYBE , bm_name, _value)


########################################### OVERRIDES
func _____OVERRIDES(): pass


func _process(_delta):
	if dragging:
		global_position = get_global_mouse_position() + offset



########################################### HELPER FUNCTIONS
func _____HELPERS(): pass



########################################### SIGNALS
func _____SIGNALS(): pass


func _on_gui_input(event) -> void:
	
	if (event is InputEventMouseButton):
		if (event.double_click):
			emit_signal("NameChangeRequested")
			return
	
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

