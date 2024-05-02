extends Control

@onready var parent = $".."
@onready var linkDrawer = $"../LinkDrawer"

func _draw():
	if (linkDrawer.visible):
		draw_dashed_line(
			parent.linkTarget.pinPosition - position,
			linkDrawer.position - position, Color(1., .0, .0, .7),
			3, 5, false
		)

func _process(_delta):
		if (linkDrawer.visible):
			position = find_parent("Workspace").find_child("Camera2D").position
			
			linkDrawer.position = get_global_mouse_position()
		queue_redraw()


func _on_link_drawer_visibility_changed():
	queue_redraw()
