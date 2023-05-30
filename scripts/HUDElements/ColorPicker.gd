extends ColorPicker


########################################### OVERRIDES

func _ready():
	position.x = get_parent().size.x * .5 - size.x * .5
	position.y = 16

func _process(delta):
#	if (visible):
#		position = Vector2.ZERO
	pass
