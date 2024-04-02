extends Control


var selectionBegin : Vector2 = Vector2.ZERO
var selectionEnd : Vector2 = Vector2.ZERO
var drawingSelection : bool = false

########################################### OVERRIDES
func _____OVERRIDES(): pass


func _draw():
	if (drawingSelection):
		draw_rect(Rect2(selectionBegin, selectionEnd - selectionBegin), Color(1,1,1,1), false)
		draw_rect(Rect2(selectionBegin, selectionEnd - selectionBegin), Color(1,1,1,.25), true)


########################################### HELPER FUNCTIONS
func _____HELPERS(): pass


func draw_selection(_drawing : bool = false, _selectionBegin : Vector2 = Vector2.ZERO, _selectionEnd : Vector2 = position) -> void:
	drawingSelection = _drawing
	
	if (_drawing):
		selectionBegin = _selectionBegin - position
		selectionEnd = _selectionEnd - position
	
	queue_redraw()



########################################### SIGNALS
func _____SIGNALS(): pass


