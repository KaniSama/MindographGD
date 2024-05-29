extends Control

@onready var noteList = $"../NoteList"
@onready var camera = $"../Camera2D"

var link_color = Color(255, 0, 0, .7)

################################################## OVERRIDES
func _draw():
	var _connections : Array = noteList.connections
	
	if (_connections.size() <= 0):
		return
	
	for i in _connections:
		var __note1 : Note = i[0]
		var __note2 : Note = i[1]
		if (is_instance_valid(__note1) && is_instance_valid(__note2)):
			if (intersectsViewport(__note1.get_rect())
			|| intersectsViewport(__note2.get_rect())
			):
				draw_line(__note1.pinPosition - position, __note2.pinPosition - position, link_color, 3, false)
		else:
			# if one of the objects does not exist,
			# delete connection from array
			noteList.connections.erase(i)

func _process(_delta):
	position = camera.position
	queue_redraw()



######################################################## HELPERS
func intersectsViewport(rect: Rect2) -> bool:
	var transform : Transform2D = get_canvas_transform()
	var Scale : Vector2 = transform.get_scale()
	return Rect2(-transform.origin / Scale, get_viewport_rect().size / Scale).intersects(rect)
