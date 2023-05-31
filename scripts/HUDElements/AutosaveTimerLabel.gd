extends Label

var _initText

func _ready():
	_initText = text

func _process(_delta: float) -> void:
	var _time = find_parent("Workspace").getTimeTillAutosave()
	
	text = _initText + str(_time)


func _input(event):
	if (event is InputEventKey && event.keycode == KEY_F && event.pressed):
		visible = !visible
