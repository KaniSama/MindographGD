extends Control

@onready var BookmarkResource : PackedScene = preload("res://scenes/bookmark.tscn")


########################################### OVERRIDES
func _____OVERRIDES(): pass


func _ready():
	pass



########################################### HELPER FUNCTIONS
func _____HELPERS(): pass


func createBookmark(_name : String = "Bookmark") -> Bookmark:
	var _bookmark : Bookmark = BookmarkResource.instantiate()
	add_child(_bookmark)
	_bookmark.dragging = true
	_bookmark.offset = -Vector2(8, 8)
	_bookmark.bm_name = _name
	return _bookmark



########################################### SIGNALS
func _____SIGNALS(): pass


func _on_child_key_pressed():
	pass
