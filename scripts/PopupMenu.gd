extends PopupMenu

func _ready():
	add_submenu_item("Change color", "PopupPanel")
	
	set_item_disabled(0, true)
	set_item_disabled(1, true)
	
	exclusive = false


func _on_visibility_changed():
	gui_disable_input = !visible
	print(gui_disable_input)
