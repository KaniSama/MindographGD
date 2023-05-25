extends Control

@onready var noteList = $"../NoteList"
@onready var camera = $"../Camera2D"


################################################## OVERRIDES
func _draw():
	if (noteList.connections.size() <= 0):
		return
	
	for i in noteList.connections:
		var note1 = i[0]
		var note2 = i[1]
		if (is_instance_valid(note1) && is_instance_valid(note2)):
			if (intersectsViewport(note1.get_rect())
			|| intersectsViewport(note2.get_rect())
			):
				draw_line(note1.pinPosition - position, note2.pinPosition - position, Color(255, 0, 0, .7), 3, false)
		else:
			# if one of the objects does not exist,
			# delete connection from array
			#print("deleting connection " + str(noteList.connections[i]))
			noteList.connections.erase(i)

func _process(delta):
	position = camera.position
	queue_redraw()



######################################################## HELPERS
func intersectsViewport(rect: Rect2) -> bool:
	var transform : Transform2D = get_canvas_transform()
	var Scale : Vector2 = transform.get_scale()
	return Rect2(-transform.origin / Scale, get_viewport_rect().size / Scale).intersects(rect)
