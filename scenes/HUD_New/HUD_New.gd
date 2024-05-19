extends Control

signal HudButtonAddPressed
signal HudButtonSavePressed
#signal HudButtonLoadPressed
signal NewNote(note : Note)
signal NewChild(note : Note)
signal NewSibling(note : Note)
signal CreateLink(note1 : Note)
signal OpenProjectRequested(projectName : String)
signal CreateProjectRequested(projectName : String)
signal OpenSettingsRequested
signal OpenReplaceRequested
signal SelectionFinished(positionOffset : Vector2, selectionRect : Rect2)

signal CreateBookmarkRequested
signal BookmarkFocusRequested(bookmarkName : String)

## Window Resources
@onready var line_edit_window_resource : PackedScene = preload("res://scenes/HUD_New/LineEditWindow.tscn")
@onready var file_dialog_window_resource : PackedScene = preload("res://scenes/HUD_New/FileDialog.tscn")
@onready var popup_menu_resource : PackedScene = preload("res://scenes/HUD_New/PopupMenu.tscn")

## RMB Menus
@onready var canvas = $CanvasLayer
#@onready var rmbMenu = $CanvasLayer/MenuBackdrop/RMBMenu
@onready var menuBackdrop = $CanvasLayer/MenuBackdrop
@onready var linkDrawer = $LinkDrawer
@onready var linkDrawerStart = $LinkDrawerStart
@onready var colorPickerBackdrop = $CanvasLayer/MenuBackdrop/ColorPickerBackdrop
@onready var colorPicker = $CanvasLayer/MenuBackdrop/ColorPickerBackdrop/ColorPicker
## IDs for the RMB-menu actions
## MUST CORELLATE WITH THE IDS IN THE WINDOW NODE ITSELF !!!
enum RmbIds {
	PIN = 0,
	LINK = 1,
	UNLINK = 3,
	DELETE = 4,
	NEW = 6,
	NEWCHILD = 7,
	NEWSIBLING = 8,
	COLOR = 10
}

## Modal Dialogs
@onready var dialogBackdrop = $CanvasLayer/DialogBackdrop
@onready var dialog = $CanvasLayer/DialogBackdrop/DialogList

@onready var projectListBackground = $CanvasLayer/DialogBackdrop/ProjectListBackground
@onready var projectList = $CanvasLayer/DialogBackdrop/ProjectListBackground/ProjectListContainer
@onready var projectNameTextBox = $CanvasLayer/DialogBackdrop/DialogList/ProjectNameTextBox

## Buttons?
@onready var buttonContainer = $CanvasLayer/ButtonContainer

## Color
var coloring = false
@onready var workspace = find_parent("Workspace")
@onready var currentColor = workspace.getLastColor()

## Selector
@onready var selector = $Selector
enum selectionModes {
	OFF = 0,
	SELECTIVE = 1,
	ADDITIVE = 2,
	SUBTRACTIVE = 3
}
var selectionMode : selectionModes = selectionModes.OFF
var selecting : bool = false
var selectionBegin : Vector2 = Vector2.ZERO
var selectionEnd : Vector2 = Vector2.ZERO

## Bookmark List
@onready var bookmarkList : ItemList = $CanvasLayer/BookmarkList/BookmarkScroll/BookmarkItemList

## Vars
var target : Note = null

var linkTarget : Note = null
var drawingLink : bool = false


############################################################# overrides
func _____OVERRIDES():pass


func _ready():
	refreshProjectList()
	# Set swatches to only have the default note color
	setColorPickerPresets([currentColor])

func _process(_delta):
	linkDrawer.visible = drawingLink
	colorPickerBackdrop.visible = coloring
	
	if (coloring && target != null):
		target.changeColor(currentColor)
	
	if (selectionMode):
		if (Input.is_action_just_pressed("lmb")):
			setSelecting()
		elif (Input.is_action_just_released("lmb")):
			setSelecting(false)
		
		if (selecting):
			selector.position = get_global_mouse_position()
			queue_redraw()
			
			selectionEnd = selector.position


func _input(event):
	if (event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed):
		if (drawingLink):
			finishLink()
	
	elif (event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_RIGHT && event.pressed):
		if (drawingLink):
			drawingLink = false
			queue_redraw()
	
	elif (event is InputEventKey && event.keycode == KEY_CTRL):
		var __changed = false
		
		if (event.pressed):
			if (selectionMode == selectionModes.OFF):
				setSelectionMode(selectionModes.SELECTIVE)
				__changed = true
		else:
			setSelectionMode(selectionModes.OFF)
			__changed = true
		
		if (__changed):
			print("Selection mode " + ("on" if selectionMode != selectionModes.OFF else "off"))


func _draw():
	if (selectionMode != selectionModes.OFF && selecting):
		selector.draw_selection(true, selectionBegin, selectionEnd)
	else:
		selector.draw_selection(false)


############################################################### get / setters
func _____GET_SETTERS():pass


func getPopupVisible() -> bool :
	return dialogBackdrop.visible || menuBackdrop.visible


func setSelectionMode(_set : selectionModes = selectionModes.SELECTIVE):
	selectionMode = _set
	
	if (_set == selectionModes.OFF):
		setSelecting(false)

func setSelecting(_set : bool = true):
	selecting = _set
	
	selectionBegin = get_global_mouse_position()
	
	queue_redraw()
	
	if (!_set):
		emit_signal("SelectionFinished", get_global_position(), Rect2(selectionBegin, selectionEnd))


func getColorPickerPresets() -> PackedColorArray:
	return colorPicker.get_presets()

func setColorPickerPresets(_colors : Array ) -> void:
	var _presets = colorPicker.get_presets()
	for __i in _presets:
		colorPicker.erase_preset(__i)
	for __i in _colors:
		colorPicker.add_preset(__i)




############################################################### helpers
func _____HELPERS():pass


func changeTarget(newTarget : Note = null):
	target = newTarget

func changeLinkTarget(newTarget : Note = null):
	linkTarget = newTarget


func showButtonContainer(_show : bool = true):
	buttonContainer.visible = _show


func showDialogBackdrop(_show : bool = true):
	showButtonContainer(!_show)
	dialogBackdrop.visible = _show

func showProjectNameChangeDialogWindow(_show : bool = true):
	showDialogBackdrop(_show)
	
	dialog.visible = _show


func showProjectList(_show : bool = true):
	showDialogBackdrop(_show)
	
	projectListBackground.visible = _show
	
	refreshProjectList()


func refreshProjectList():
	setProjectList(workspace.getProjectList())

func setProjectList(projects : Array):
	projectList.clear()
	projectList.add_item("+ New Project!", load("res://sprites/sPin.png"), true)
	projectList.add_item("", null, false)
	
	for project in projects:
		projectList.add_item(project, null, true)


func setBookmarkList(_bookmarks : Array = [] ) -> void:
	bookmarkList.clear()
	for __i in _bookmarks:
		bookmarkList.add_item(__i.bm_name)
		#DELETE printt(__i.bm_name)

func getBookmarkList() -> Array [ String ]:
	var _output : Array [ String ] = []
	for __i in range(bookmarkList.item_count):
		_output.append(bookmarkList.get_item_text(__i))
	return _output




############################################################### RMB MENU
func _____RMB_MENU():pass


func openRmbMenu():
	#DELETE: rmbMenu.visible = true
	#var mpos = get_viewport().get_mouse_position()
	#rmbMenu.position.x = clamp(mpos.x, 0, get_viewport_rect().size.x - rmbMenu.size.x)
	#rmbMenu.position.y = clamp(mpos.y, 0, get_viewport_rect().size.y - rmbMenu.size.y)
	#menuBackdrop.visible = true
	# TODO: RMB menu
	var _menu : PopupMenu = popup_menu_resource.instantiate()
	_menu.id_pressed.connect(process_rmb_menu)

func process_rmb_menu(command_id : int):
	var closeMenu : bool = true
	
	#DELETE: rmbMenu.deselect_all()
	match (command_id):
		
		RmbIds.PIN:
			target.pin()
			
		RmbIds.LINK:
			changeLinkTarget(target)
			startLink()
			
		RmbIds.NEW:
			emit_signal("NewNote", target)
			
		RmbIds.DELETE:
			target.queue_free()
			
		RmbIds.UNLINK:
			target.removeFromConnections()
			
		RmbIds.COLOR:
			closeMenu = false
			
			var mouseP = get_viewport().get_mouse_position()
			
			currentColor = target.color
			colorPicker.color = target.color
			colorPickerBackdrop.position.x = clamp(mouseP.x, 0, get_viewport_rect().end.x-colorPickerBackdrop.size.x)
			colorPickerBackdrop.position.y = clamp(mouseP.y, 0, get_viewport_rect().end.y-colorPickerBackdrop.size.y)
			coloring = true
			
		RmbIds.NEWCHILD:
			print("child")
			emit_signal("NewChild", target)
			
		RmbIds.NEWSIBLING:
			print("sibling")
			emit_signal("NewSibling", target)
	
	if (closeMenu):
		closeRmbMenu()

func closeRmbMenu():
	#DELETE: rmbMenu.visible = false
	#menuBackdrop.visible = false
	#coloring = false
	# TODO: also that
	pass



############################################################### LINK
func _____LINK():pass

func startLink():
	drawingLink = true

func finishLink():
	emit_signal("CreateLink", linkTarget)
	
	drawingLink = false
	queue_redraw()



############################################################### SELECTION
func _____SELECTION():pass

func pointWithin(_point : Vector2, _posStart : Vector2, _posEnd : Vector2) -> bool:
	return (
		_point.x >= _posStart.x
		&& _point.x <= _posEnd.x
		&& _point.y >= _posStart.y
		&& _point.y <= _posEnd.y
	)

func noteWithin(_note : Note, _posStart : Vector2, _posEnd : Vector2) -> bool:
	var _noteCorners = [
		_note.position,
		Vector2(_note.position.x + _note.size.x, _note.position.y),
		Vector2(_note.position.x, _note.position.y + _note.size.y),
		_note.position + _note.size
	]
	
	for i in _noteCorners:
		if (pointWithin(i, _posStart, _posEnd)):
			return true
	
	return false



################################################################## signals
func _____SIGNALS():pass


func _on_button_pressed():
	emit_signal("HudButtonAddPressed")

func _on_button_save_pressed():
	emit_signal("HudButtonSavePressed")

func _on_button_load_pressed():
#	emit_signal("HudButtonLoadPressed")
	showProjectList()

func _on_button_add_bookmark_pressed():
	emit_signal("CreateBookmarkRequested")



func _on_menu_backdrop_gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT):
		closeRmbMenu()

func _on_color_picker_color_changed(color):
	currentColor = color
	workspace.setLastColor(color)



func _on_rmb_menu_item_clicked(index, at_position, mouse_button_index):
	if (mouse_button_index == MOUSE_BUTTON_LEFT):
		var closeMenu : bool = true
		
		#DELETE: rmbMenu.deselect_all()
		match (index):
			
			RmbIds.PIN:
				#print("pin")
				target.pin()
				
			RmbIds.LINK:
				#print("link")
				changeLinkTarget(target)
				startLink()
				
			RmbIds.NEW:
				#print("new")
				emit_signal("NewNote", target)
				
			RmbIds.DELETE:
				#print("deleb")
				target.queue_free()
				
			RmbIds.UNLINK:
				#print("unlink")
				target.removeFromConnections()
				
			RmbIds.COLOR:
				#print("colore")
				closeMenu = false
				
				#var mouseP = rmbMenu.position + at_position
				var mouseP = get_global_mouse_position()
				
				currentColor = target.color
				colorPicker.color = target.color
				colorPickerBackdrop.position.x = clamp(mouseP.x, 0, get_viewport_rect().end.x-colorPickerBackdrop.size.x)
				colorPickerBackdrop.position.y = clamp(mouseP.y, 0, get_viewport_rect().end.y-colorPickerBackdrop.size.y)
				coloring = true
				
			RmbIds.NEWCHILD:
				print("child")
				emit_signal("NewChild", target)
				
			RmbIds.NEWSIBLING:
				print("sibling")
				emit_signal("NewSibling", target)
		
		if (closeMenu):
			closeRmbMenu()




func _on_project_list_button_open_dir_pressed():
	setProjectList(workspace.getProjectList())
	OS.shell_open(ProjectSettings.globalize_path("user://Projects"))

func _on_project_list_button_cancel_pressed():
	showProjectList(false)


func _on_project_list_container_item_activated(index):
	if (index == 0):
		showProjectList(false)
		showProjectNameChangeDialogWindow()
		return
	
	var projectName : String = projectList.get_item_text(index)
	emit_signal("OpenProjectRequested", projectName)
	showProjectList(false)

func _on_project_list_container_item_clicked(index, _at_position, _mouse_button_index):
	if (index == 0):
		showProjectList(false)
		showProjectNameChangeDialogWindow()
		return



func _on_dialog_button_cancel_pressed():
	showProjectNameChangeDialogWindow(false)
	showProjectList()

func _on_dialog_button_ok_pressed():
	var _text = projectNameTextBox.text.strip_edges().replacen(".mg", "")
	
	if (_text):
		emit_signal("CreateProjectRequested", _text)
		showProjectNameChangeDialogWindow(false)




func _on_button_settings_pressed():
	emit_signal("OpenSettingsRequested")

func _on_button_replace_pressed():
	emit_signal("OpenReplaceRequested")




func _on_bookmark_item_list_item_activated(index):
	emit_signal("BookmarkFocusRequested", bookmarkList.get_item_text(index))
