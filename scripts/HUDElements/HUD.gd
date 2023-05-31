extends Control

signal HudButtonAddPressed
signal HudButtonSavePressed
signal HudButtonLoadPressed
signal NewNote(note : Note)
signal CreateLink(note1 : Note)
signal OpenProjectRequested(projectName : String)
signal CreateProjectRequested(projectName : String)
signal OpenSettingsRequested

## RMB Menus
@onready var canvas = $CanvasLayer
@onready var rmbMenu = $CanvasLayer/MenuBackdrop/RMBMenu
@onready var menuBackdrop = $CanvasLayer/MenuBackdrop
@onready var linkDrawer = $LinkDrawer
@onready var linkDrawerStart = $LinkDrawerStart
@onready var colorPicker = $CanvasLayer/MenuBackdrop/ColorPickerBackdrop

## Modal Dialogs
@onready var dialogBackdrop = $CanvasLayer/DialogBackdrop
@onready var dialog = $CanvasLayer/DialogBackdrop/DialogList

@onready var projectListBackground = $CanvasLayer/DialogBackdrop/ProjectListBackground
@onready var projectList = $CanvasLayer/DialogBackdrop/ProjectListBackground/ProjectListContainer
@onready var projectNameTextBox = $CanvasLayer/DialogBackdrop/DialogList/ProjectNameTextBox

## Buttons?
@onready var buttonContainer = $CanvasLayer/ButtonContainer

## Colour
var coloring = false
@onready var parent = get_parent()
@onready var currentColour = parent.getLastColour()

## Vars
var target : Note = null

var linkTarget : Note = null
var drawingLink : bool = false

############################################################# overrides
func _____OVERRIDES():pass

func _ready():
	refreshProjectList()

func _process(delta):
	linkDrawer.visible = drawingLink
	colorPicker.visible = coloring
	
	if (coloring && target != null):
		target.changeColour(currentColour)


func _input(event):
	if (event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed):
		if (drawingLink):
			finishLink()
	
	elif (event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_RIGHT && event.pressed):
		if (drawingLink):
			drawingLink = false
			queue_redraw()




############################################################### get / setters
func _____GET_SETTERS():pass

func getPopupVisible() -> bool :
	return dialogBackdrop.visible || menuBackdrop.visible


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
	setProjectList(get_parent().getProjectList())

func setProjectList(projects : Array):
	projectList.clear()
	projectList.add_item("+ New Project!", load("res://sprites/sPin.png"), true)
	projectList.add_item("", null, false)
	
	for project in projects:
		projectList.add_item(project, null, true)


############################################################### RMB MENU
func _____RMB_MENU():pass

func openRmbMenu():
	rmbMenu.visible = true
	var mpos = get_viewport().get_mouse_position()
	rmbMenu.position.x = clamp(mpos.x, 0, get_viewport_rect().size.x - rmbMenu.size.x)
	rmbMenu.position.y = clamp(mpos.y, 0, get_viewport_rect().size.y - rmbMenu.size.y)
	menuBackdrop.visible = true

func closeRmbMenu():
	rmbMenu.visible = false
	menuBackdrop.visible = false
	coloring = false


############################################################### LINK
func _____LINK():pass

func startLink():
	drawingLink = true

func finishLink():
	emit_signal("CreateLink", linkTarget)
	
	drawingLink = false
	queue_redraw()



################################################################## signals
func _____SIGNALS():pass

func _on_button_pressed():
	emit_signal("HudButtonAddPressed")

func _on_button_save_pressed():
	emit_signal("HudButtonSavePressed")

func _on_button_load_pressed():
#	emit_signal("HudButtonLoadPressed")
	showProjectList()



func _on_menu_backdrop_gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT):
		closeRmbMenu()

func _on_color_picker_color_changed(color):
	currentColour = color
	get_parent().setLastColour(color)



func _on_rmb_menu_item_clicked(index, at_position, mouse_button_index):
	if (mouse_button_index == MOUSE_BUTTON_LEFT):
		var closeMenu : bool = true
		
		rmbMenu.deselect_all()
		match (index):
			
			rmbMenu.RmbIds.PIN:
				print("pin")
				target.pin()
				
			rmbMenu.RmbIds.LINK:
				print("link")
				changeLinkTarget(target)
				startLink()
				
			rmbMenu.RmbIds.NEW:
				print("new")
				emit_signal("NewNote", target)
				
			rmbMenu.RmbIds.DELETE:
				print("deleb")
				target.queue_free()
				
			rmbMenu.RmbIds.UNLINK:
				print("unlink")
				target.removeFromConnections()
				
			rmbMenu.RmbIds.COLOUR:
				print("colore")
				closeMenu = false
				
				var mouseP = rmbMenu.position + at_position
				
				currentColour = target.colour
				colorPicker.find_child("ColorPicker", false).color = target.colour
				colorPicker.position.x = clamp(mouseP.x, 0, get_viewport_rect().end.x-colorPicker.size.x)
				colorPicker.position.y = clamp(mouseP.y, 0, get_viewport_rect().end.y-colorPicker.size.y)
				coloring = true
		
		if (closeMenu):
			closeRmbMenu()




func _on_project_list_button_open_dir_pressed():
	setProjectList(get_parent().getProjectList())
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

func _on_project_list_container_item_clicked(index, at_position, mouse_button_index):
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
