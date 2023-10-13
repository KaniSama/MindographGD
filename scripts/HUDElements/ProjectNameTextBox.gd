extends LineEdit

var regex : RegEx = RegEx.new()
var last_line = ""
var last_caret = 0

########################################### OVERRIDES


########################################### HELPER FUNCTIONS


########################################### SIGNALS


func _on_text_changed(new_text : String):
	if (new_text.is_valid_filename() || new_text.is_empty()):
		last_line = new_text
		last_caret = caret_column
	else:
		text = last_line
		caret_column = last_caret
