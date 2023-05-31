extends Control

signal rmbNote(note : Note)
#signal startLink(note: Note)

signal linkNextTargetChanged(note : Note)
var linkNextTarget : Note = null

######## IMPORTANT: MARKER FOR READING THE SAVE FILE ON NEXT FRAME
var readOnNextFrame = [false, ""]


@onready var connections : Array = []
@onready var noteResource : Resource

var nextNoteUID : int = 0


###################################################### OVERRIDES
func _____OVERRIDES():pass

func _ready():
	noteResource = preload("res://note/note.tscn")

func _process(delta):
	if (readOnNextFrame[0]):
		await get_tree().process_frame
		
		loadFromFile(readOnNextFrame[1])
		readOnNextFrame = [false, ""]



############################################### Note control
func _____NOTE_CONTROL():pass

# Nukes the whole note list
func clearNotesAndConnections():
	nextNoteUID = 0
	
	connections = []
	
	for note in get_children():
		note.queue_free()
	
	queue_redraw()

func addNote() -> Note:
	var newNote : Node = noteResource.instantiate()
	
	add_child(newNote)
	connectNoteSignals(newNote)
	
	newNote.UID = getNextUID()
	
	newNote.changeColour(get_parent().getLastColour())
	
	newNote.position = get_global_mouse_position()
	newNote.dragging = true
	newNote.offset = - Vector2(newNote.size.x * .5, 16)
	
	newNote.show_behind_parent = true
	
	return newNote

func addNoteFromContext(_UID:int, _text:String, _position:Vector2, _size:Vector2, _color:Color, _pinned:bool) -> Note:
	var newNote : Node = noteResource.instantiate()
	
	add_child(newNote)
	connectNoteSignals(newNote)
	
	newNote.UID = _UID
	
	newNote.changeColour(_color)
	
	newNote.position = _position
	newNote.dragging = false
	
	newNote.pinned = !_pinned
	newNote.pin()
	
	newNote.size = _size
	
	newNote.show_behind_parent = true
	
	newNote.setText(_text)
	
	return newNote

func duplicateNote(note : Note) -> Note:
	var newNote : Node = noteResource.instantiate()
	
	add_child(newNote)
	connectNoteSignals(newNote)
	
	newNote.UID = nextNoteUID
	nextNoteUID += 1
	
	newNote.find_child("TextEdit").text = note.find_child("TextEdit").text
	newNote.changeColour(note.colour)
	
	newNote.position = get_global_mouse_position()
	newNote.dragging = true
	newNote.offset = - Vector2(newNote.size.x * .5, 16)
	
	newNote.show_behind_parent = true
	
	return newNote

func connectNoteSignals(note: Note):
	note.connect("clicked", noteClicked.bind(note))
	note.connect("RemoveFromConnections", removeFromConnections)
	note.connect("hovered", changeLinkNextTarget)
	note.connect("unhovered", untarget)
	#newNote.connect("ColourRequested", changeColour)

func changeColour(note):
	note.changeColour(get_parent().getLastColor())



######################################################## CONNECTIONS
func _____CONNECTIONS():pass

func addConnection(note1, note2):
	if (note1 != note2 && !connections.has( [note1, note2] ) && !connections.has( [note2, note1] )):
		connections.append( [note1, note2] )

func connectionRequest(note : Note):
	# iterate across all child notes
	var children = get_children()
	for i in range(children.size()-1, -1, -1):
		# figure out which one is under the mouse
		if (children[i].get_global_rect().has_point(get_global_mouse_position())):
			# create connection with that note
			addConnection(note, children[i])
			break

func removeFromConnections(note):
	for i in range(connections.size()-1, -1, -1):
		if (connections[i].has(note)):
			connections.remove_at(i)
#			print("removing connection " + connections[i])
#	for i in connections:
#		if (i.has(note)):
#			connections.erase(i)
#			print("removing connection " + str(i))

func changeLinkNextTarget(note):
	linkNextTarget = note
	emit_signal("linkNextTargetChanged", linkNextTarget)
	print(linkNextTarget)

func untarget(note):
	if (note == linkNextTarget):
		linkNextTarget = null
		emit_signal("linkNextTargetChanged", linkNextTarget)
		print(linkNextTarget)


################################################## NOTE RENDER ORDER
func _____NOTE_ORDER():pass

func noteClicked(event, note):
	putNoteOnTop(note)
	
	if (event is InputEventMouseButton):
		match (event.button_index):
			MOUSE_BUTTON_RIGHT:
				emit_signal("rmbNote", note)
#			MOUSE_BUTTON_LEFT:
#				if (note.pinned):
#					emit_signal("startLink", note)

func putNoteOnTop(note):
	move_child(note, get_child_count()-1)



################################################## NOTE UIDS
func _____NOTE_UIDS():pass
func getNoteByUID(_UID : int) -> Note:
	for _note in get_children():
		if (is_instance_valid(_note) && _note.UID == _UID):
			return _note
	
	return null

func UIDExists(_UID : int) -> bool:
	for _note in get_children():
		if (_UID == _note.UID):
			return true
	
	return false

func reshuffleUIDs():
	nextNoteUID = 0
	
	for _note in get_children():
		_note.UID = getNextUID()

func getNextUID() -> int:
	while (UIDExists(nextNoteUID)):
		nextNoteUID += 1
	
	return nextNoteUID


################################################ SAVE / LOAD SYSTEM
func _____SAVE_LOAD():pass

func saveToFile():
	var projectName : String = get_parent().getProjectName()
	
	var file = FileAccess.open(
		"user://Projects/" + projectName.replacen(".mg", "") + ".mg",
		FileAccess.WRITE
	)
	
	if (file == null):
		OS.alert("Unable to open file " + ProjectSettings.globalize_path("user://Projects/" + projectName.replacen(".mg", "") + ".mg"))
		return
	
	## Save Parameters
	# Project Name (string)
	file.store_line(projectName)
	# Next UID (int)
	file.store_64(nextNoteUID)
	# NoteList Size (int)
	var _notes = get_children()
	file.store_64(_notes.size())
	# Foreach Note:
	for note in _notes:
		## UID (int)
		file.store_64(note.UID)
		## Text Buffer Length (int)
		var _text : String = note.getText()
		var _text_buffer = var_to_bytes(_text)
		file.store_64(_text_buffer.size())
		file.store_buffer(_text_buffer)
		## Position (Vector2)
		file.store_float(note.position.x)
		file.store_float(note.position.y)
		## Size (Vector2)
		file.store_float(note.size.x)
		file.store_float(note.size.y)
		## Pinned (bool)
		file.store_8(note.pinned)
		## Color
		file.store_var(note.colour)
	# Connection Size (int)
	file.store_64(connections.size())
	# Foreach Connection:
	for connection in connections:
		## Connection[0].UID (int)
		## Connection[1].UID (int)
		printt(connection[0].UID, connection[1].UID)
		file.store_64(connection[0].UID)
		file.store_64(connection[1].UID)
	
	file.flush()
	file.close()

func loadFromFile(projectName):
#	var projectName : String = get_parent().getProjectName()
	
	var file = FileAccess.open(
		"user://Projects/" + projectName.replacen(".mg", "") + ".mg",
		FileAccess.READ
	)
	
	if (file == null):
		OS.alert("Unable to open file " + ProjectSettings.globalize_path("user://Projects/" + projectName.replacen(".mg", "") + ".mg"))
		return
	
	## Save Parameters
	# Project Name (string)
	projectName = file.get_line()
	# Next UID (int)
	nextNoteUID = file.get_64()
	# NoteList Size (int)
	var _notes = file.get_64()
	# Foreach Note:
	for note in range(_notes):
		## UID (int)
		var _UID = file.get_64()
		#var _buf_length = file.get_64()
		var _text_buff_length = file.get_64()
		var _text = bytes_to_var(file.get_buffer(_text_buff_length))
		var _position = Vector2(file.get_float(), file.get_float())
		var _size = Vector2(file.get_float(), file.get_float())
		var _pinned = file.get_8()
		var _color = file.get_var()
		var _note = addNoteFromContext(_UID, _text, _position, _size, _color, _pinned)
		_note.updatePinPosition()
	# Connection Size (int)
	var _connection_size = file.get_64()
	# Foreach Connection:
	for connectionHalf in range(_connection_size):
		## Connection[0].UID (int)
		## Connection[1].UID (int)
		var _UID1 = file.get_64()
		var _UID2 = file.get_64()
#		printt(_UID1, _UID2)
		
		addConnection(getNoteByUID(_UID1), getNoteByUID(_UID2))
		#print(connections[connectionHalf])
	queue_redraw()
	
	file.close()
	
	reshuffleUIDs()

