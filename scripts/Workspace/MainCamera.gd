extends Camera2D

@onready
var BG : TextureRect
var GRIDSIZE : Vector2
var gridPosition : Vector2
var BGPositionCenter : Vector2

var grab : Vector2
var grabbed : bool = false

var unzoomPosition : Vector2
var unzooming : bool = false

func _ready():
	BG = get_parent().find_child("Background", false)
	gridPosition = Vector2.ZERO
	GRIDSIZE = BG.texture.get_size()
	BGPositionCenter = Vector2(BG.size.x/2, BG.size.y/2)

func _process(delta):
	
	# Handle camera grab offset
	if (Input.is_action_just_pressed("mmb")):
		grabbed = true
		grab = get_global_mouse_position()
	
	# Handle camera grab maths + BG scrolling
	if (grabbed):
		position += grab - get_global_mouse_position()
		
		gridPosition.x = round(position.x / GRIDSIZE.x)
		gridPosition.y = round(position.y / GRIDSIZE.y)
		
		BG.position = gridPosition * GRIDSIZE - GRIDSIZE - BGPositionCenter
		
		
		if (Input.is_action_pressed("mmb")):
			# Warp mouse if dragging screen outside of workspace view
			var _mouse = get_viewport().get_mouse_position()
			var _size = get_viewport_rect().size
			
			var _padding : Vector2 = Vector2(5, 5)
			var _padding_sm : Vector2 = Vector2(2, 2)
			var _regrab = false
			
			if (_mouse.x > _size.x - _padding_sm.x):
				_regrab = true
				get_viewport().warp_mouse(Vector2(_mouse.x - _size.x + _padding.x , _mouse.y))
			if (_mouse.x < 0 + _padding_sm.x):
				_regrab = true
				get_viewport().warp_mouse(Vector2(_mouse.x + _size.x - _padding.x , _mouse.y))
			if (_mouse.y > _size.y - _padding_sm.y):
				_regrab = true
				get_viewport().warp_mouse(Vector2(_mouse.x, _mouse.y - _size.y + _padding.y))
			if (_mouse.y < 0 + _padding_sm.y):
				_regrab = true
				get_viewport().warp_mouse(Vector2(_mouse.x, _mouse.y + _size.y - _padding.y))
			
			if (_regrab):
				grab = get_global_mouse_position()
	
	
	if (Input.is_action_just_released("mmb")):
		grabbed = false
	
	# Handle zoom
	if (Input.is_action_just_released("mwdn")):
		zoom *= .9
	elif (Input.is_action_just_released("mwup")):
		zoom *= 1.1
	if (Input.is_action_just_pressed("ui_home")):
		# smooth unzoom:
		unzooming = true
		unzoomPosition = get_global_mouse_position()
		# instant unzoom:
		#position = get_global_mouse_position()
		#zoom = Vector2(1,1)
	if (unzooming):
		unzoom(delta)
	zoomClamp()
	

func zoomClamp():
	zoom = Vector2( clampf(zoom.x, .1, 50), clampf(zoom.y, .1, 50) )

func unzoom(delta):
	if (zoom.is_equal_approx(Vector2(1, 1))):
		zoom = Vector2(1,1)
		unzooming = false
		return
	
	zoom += (Vector2(1,1) - zoom) * delta * 50
	position += (unzoomPosition - position) * delta * 50



