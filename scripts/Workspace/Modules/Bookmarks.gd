@icon("res://sprites/script_icons/list.svg")

extends Control

@onready var BookmarkResource : PackedScene = preload("res://scenes/bookmark.tscn")


########################################### OVERRIDES
func _____OVERRIDES(): pass


func _ready():
	pass



########################################### HELPER FUNCTIONS
func _____HELPERS(): pass


func createBookmark(_name : String = "Bookmark", _position : Vector2 = Vector2.ZERO) -> Bookmark:
	var _bookmark : Bookmark = BookmarkResource.instantiate()
	var _names : Array [ String ] = []
	for __i : Bookmark in get_children():
		_names.append(__i.bm_name)
	add_child(_bookmark)
	if not _position.is_equal_approx(Vector2.ZERO):
		_bookmark.dragging = false
		_bookmark.position = _position
	else:
		_bookmark.dragging = true
	_bookmark.offset = -Vector2(8, 8)
	while (_name in _names):
		_name += "_"
	_bookmark.bm_name = _name
	return _bookmark


func clearBookmarks():
	for __i in get_children():
		__i.queue_free()


########################################### SIGNALS
func _____GET_SETTERS(): pass


func get_bookmarks_as_dict() -> Dictionary:
	var output : Dictionary = {
		"name" = [],
		"position" = []
	}
	
	for __bm : Bookmark in get_children():
		output.name.append(__bm.bm_name)
		output.position.append(__bm.position)
	
	return output

func set_bookmarks_from_dict(_bms : Dictionary) -> void:
	var _bm_name = _bms["name"]
	var _bm_pos = _bms["position"]
	
	for __i in range(_bm_name.size()):
		createBookmark(_bm_name[__i], _bm_pos[__i])


