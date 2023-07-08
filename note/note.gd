extends Panel
class_name Note

signal clicked
signal hovered(note : Note)
signal unhovered(note : Note)
signal RemoveFromConnections(note : Note)
signal SelectedClick(note : Note)
signal SelectedRect(note : Note)
#signal ColourRequested(note : Note)

var UID : int
@onready var colour : Color
@onready var noteBg = $NoteContainer/NoteBg

var pinPosition : Vector2 = Vector2.ZERO
var pinned : bool = false

var selected : bool = false

@onready var dragger = $NoteContainer/Dragger
@onready var pinIcon = $NoteContainer/PinIcon
@onready var pinShadow = $NoteContainer/PinIcon2
var dragging : bool = false
var offset : Vector2

@onready var resizer = $NoteContainer/Resizer
var resizing : bool = false

@onready var okButton = $NoteContainer/OkButton
@onready var cancelButton = $NoteContainer/CancelButton
@onready var textEdit = $NoteContainer/TextWrapper/TextEdit
@onready var textWrapper = $NoteContainer/TextWrapper
@onready var noteText = $NoteContainer/TextWrapper/NoteText
var editing = false

@onready var dropShadow = $NoteContainer/DropShadow


################################################## OVERRIDES
func _____OVERRIDES():pass

func _ready():
	# Disable Text Edit elements
	exitTextEditMode(false)
	#requestLastColour(self)

func _process(delta):
	if (!pinned):
		if (dragging):
			drag()
			dropShadow.visible = true
		else:
			dropShadow.visible = false
		
		if (resizing):
			resize()
	else:
		dropShadow.visible = false


################################################## SIZE / POSITION CONTROLS
func _____SIZE_POS():pass

func onDragStart():
	offset = position - get_global_mouse_position()
	dragging = true

func onDragStop():
	dragging = false

func drag():
	position = get_global_mouse_position() + offset
	updatePinPosition()


func onResizeStart():
	offset = get_global_mouse_position() - size
	resizing = true

func onResizeStop():
	resizing = false

func resize():
	size = get_global_mouse_position() - offset
	updatePinPosition()


func pin():
	pinned = !pinned
	dragger.modulate = Color(0,0,0,0) if pinned else Color(1,1,1,.3882352)
	
	pinIcon.visible = pinned
	pinShadow.visible = pinned
	resizer.visible = !pinned
	
	if (pinned):
		dragger.mouse_default_cursor_shape = CursorShape.CURSOR_POINTING_HAND
	else:
		dragger.mouse_default_cursor_shape = CursorShape.CURSOR_DRAG

func updatePinPosition():
	pinPosition.x = position.x + size.x * .5
	pinPosition.y = position.y + 8


################################################### MODES
func _____TEXT_EDIT():pass

func enterTextEditMode():
	textEdit.visible = true
	okButton.visible = true
	cancelButton.visible = true
	
	textEdit.set_process(true)
	okButton.set_process(true)
	cancelButton.set_process(true)
	
	textEdit.text = noteText.text
	
	textEdit.grab_focus()
	textEdit.select_all()

func exitTextEditMode(saveText: bool):
	textEdit.visible = false
	okButton.visible = false
	cancelButton.visible = false
	
	textEdit.set_process(false)
	okButton.set_process(false)
	cancelButton.set_process(false)
	
	if (saveText):
		noteText.text = textEdit.text



#################################################### GET/SETTERS
func _____GET_SETTERS():pass

func changeColour(newColour : Color):
	noteBg.set_modulate(newColour)
	colour = newColour


func getText() -> String:
	return noteText.text

func setText(_text : String):
	noteText.text = _text
	textEdit.text = _text

func getEscapedText() -> String:
	return noteText.text.c_escape()



################################################### SIGNALS
func _____SIGNALS():pass

func removeFromConnections():
	emit_signal("RemoveFromConnections", self)

func emitClicked(event = null):
	emit_signal("clicked", event)

func emitHovered(note = self):
	emit_signal("hovered", note)

func emitUnhovered(note = self):
	emit_signal("hovered", note)

#func requestLastColour(note: Note):
#	emit_signal("ColourRequested", note)

func _____TRUE_SIGNALS():pass

func _on_dragger_gui_input(event):
	if (event is InputEventMouseButton):
		emitClicked(event)
		
		if (event.is_action_pressed("lmb")):
			onDragStart()
		elif (event.is_action_released("lmb")):
			onDragStop()
		
		if (event.double_click):
			pin()

func _on_resizer_gui_input(event):
	if (event is InputEventMouseButton):
		emitClicked(event)
		
		if (event.is_action_pressed("lmb")):
			onResizeStart()
		elif (event.is_action_released("lmb")):
			onResizeStop()

func _on_text_wrapper_gui_input(event):
	if (event is InputEventMouseButton):
		emitClicked(event)
		
		if (event.double_click):
			enterTextEditMode()

func _on_ok_button_pressed():
	exitTextEditMode(true)
	
	emitClicked()

func _on_cancel_button_pressed():
	exitTextEditMode(false)
	
	emitClicked()


func _on_text_edit_gui_input(event):
	if (event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT):
		emitClicked(event)

func _on_note_bg_gui_input(event):
	if (event is InputEventMouseButton):
		emitClicked(event)
		pass


func _on_mouse_entered():
	emitHovered(self)

func _on_mouse_exited():
	emitUnhovered(self)



func _on_gui_input(event):
	if (event is InputEventMouseButton):
		emitClicked(event)
