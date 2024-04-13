extends Control

signal rmbNote(note : Note)
#signal startLink(note: Note)

signal linkNextTargetChanged(note : Note)
var linkNextTarget : Note = null

######## IMPORTANT: MARKER FOR READING THE SAVE FILE ON NEXT FRAME
var readOnNextFrame = [false, ""]


@onready var selected : Array = []

@onready var connections : Array = []
@onready var noteResource : Resource

var nextNoteUID : int = 0


###################################################### OVERRIDES
func _____OVERRIDES():pass

func _ready():
	noteResource = preload("res://note/note.tscn")

func _process(delta):
#	if (Input.is_action_just_pressed("debug")):
#		for n in get_children():
#			print(n.UID)
	
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
	
	newNote.setUID(getNextUID())
	
	newNote.changeColour(get_parent().getLastColour())
	newNote.setDarkMode(get_parent().getDarkMode())
	
	newNote.position = get_global_mouse_position()
	newNote.dragging = true
	newNote.offset = - Vector2(newNote.size.x * .5, 16)
	
	newNote.show_behind_parent = true
	
	return newNote

func addNoteFromContext(_UID:int, _text:String, _position:Vector2, _size:Vector2, _color:Color, _pinned:bool) -> Note:
	var newNote : Node = noteResource.instantiate()
	
	add_child(newNote)
	connectNoteSignals(newNote)
	
#	newNote.UID = _UID
	newNote.setUID(_UID)
	
	newNote.changeColour(_color)
	newNote.setDarkMode(get_parent().getDarkMode())
	
	newNote.position = _position
	newNote.dragging = false
	
	newNote.pinned = !_pinned
	newNote.pin()
	
	newNote.size = _size
	
	newNote.show_behind_parent = true
	
	newNote.setText(_text)
	
	return newNote

func duplicateNote(note : Note) -> Note:
	var newNote : Node = addNoteFromContext(
		note.UID,
		note.getText(), 
		note.position, 
		note.size, 
		note.colour, 
		note.pinned
	)
	
	return newNote

func connectNoteSignals(note: Note):
	note.connect("clicked", noteClicked.bind(note))
	note.connect("RemoveFromConnections", removeFromConnections)
	note.connect("hovered", changeLinkNextTarget)
	note.connect("unhovered", untarget)
	#newNote.connect("ColourRequested", changeColour)

func changeColour(note):
	note.changeColour(get_parent().getLastColor())


func replaceTextInNotes(_what : String, _forWhat : String, _whole : bool, _ignoreCase : bool) -> int:
	var _notesChanged : int = 0
	var _notes = get_children()
	
	printt(_notes)
	for _note in _notes:
		var _text = _note.getText()
	
		if (_whole):
			var _found = []
			var _length = _what.length()
			
			var _position = 0
			while ((_text.findn(_what, _position) if _ignoreCase else _text.find(_what, _position)) > -1):
				_position = (_text.findn(_what, _position) if _ignoreCase else _text.find(_what, _position))
				
				if (_position == 0 || _text[_position-1] in " .,/?\\<>!@#$%^&*()[]{}|\n\t\b\a\"\';:~`"):
					if (_position + _length >= _text.length()):
						_found.append(_position)
						break
					elif (_text[_position + _length] in " .,/?\\<>!@#$%^&*()[]{}|\n\t\b\a\"\';:~`"):
						_found.append(_position)
				
				_position += 1
			
			var _final = ""
			var i = 0
			while i in range(_text.length()):
				if (i in _found):
					_final += _forWhat
					
					i += _length
					continue
				
				_final += _text[i]
				i += 1
			
			if (_final != _text):
				_note.setText(_final)
				_notesChanged += 1
			
		else:
			
			if (_ignoreCase):
				_note.setText(_text.replacen(_what, _forWhat).strip_edges())
			else:
				_note.setText(_text.replace(_what, _forWhat).strip_edges())
			
			if (_text != _note.getText()):
				_notesChanged += 1
	
	return _notesChanged

func setNoteDarkMode(_set : bool = true):
	for n:Note in get_children():
		n.setDarkMode(_set)



######################################################## CONNECTIONS
func _____CONNECTIONS():pass

func getAllNoteConnections(note : Note) -> Array[ Note ]:
	var _con = connections.filter(func(x): return note in x)
	var _output : Array [ Note ]
	for __i in _con:
		_output.append(__i[1] if __i[0]==note else __i[0])
	return _output

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
		if (note in connections[i]):
			connections.remove_at(i)

func changeLinkNextTarget(note):
	linkNextTarget = note
	emit_signal("linkNextTargetChanged", linkNextTarget)
	print(linkNextTarget)

func untarget(note):
	if (note == linkNextTarget):
		linkNextTarget = null
		emit_signal("linkNextTargetChanged", linkNextTarget)
		print(linkNextTarget)



######################################################## SELECTION
func _____SELECTION():pass

func setSelected(_note : Note, _selected : bool = true):
	if (is_instance_valid(_note) && _note not in selected):
		selected.append(_note)
	elif (!_selected):
		selected.erase(_note)

func setSelectedMultiple(_notes : Array, _selected : bool = true):
	for _note in _notes:
		setSelected(_note, _selected)

func clearSelected():
	selected = []



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
		_note.setUID(getNextUID())

func getNextUID() -> int:
	while (UIDExists(nextNoteUID)):
		nextNoteUID += 1
	
	return nextNoteUID


################################################ SAVE / LOAD SYSTEM
func _____SAVE_LOAD():pass

func saveToFile():
	reshuffleUIDs()
	
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
		#printt(connection[0].UID, connection[1].UID)
		file.store_64(connection[0].UID)
		file.store_64(connection[1].UID)
	
	# Store colour picker presets per save file
	var _colorPickerPresets : PackedColorArray = \
		get_parent().getColorPickerPresets()
	file.store_64(_colorPickerPresets.size())
	for __color in _colorPickerPresets:
		file.store_var(__color)
	
	# Store a buffer value (may or may not help with connections being broken)
	file.store_8(0)
	
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
		var _color : Color = file.get_var()
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
	
	# Read colour presets per save file
	var _colorPresetsArraySize = file.get_64()
	var _colorPresets : Array[Color] = []
	if _colorPresetsArraySize > 0:
		for __i in range(_colorPresetsArraySize):
			_colorPresets.append(file.get_var())
	get_parent().setColorPickerPresets(_colorPresets)
	
	queue_redraw()
	
	file.close()
	
	reshuffleUIDs()

