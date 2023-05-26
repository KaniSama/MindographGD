extends Control
class_name Workspace

const AppName = "                 [Mindograph]"

var ProjectName : String = "NewMindographProject.mg"
var ProjectList : Array = []
var modified : bool = false

@onready var hud : Node = $HUD
@onready var noteList : Node = $NoteList

@onready var exitConfirmationDialog = $ExitConfirmationDialog

var lastColour: Color = Color.KHAKI


func _ready():
	
	## Gets list of previously created projects
	initProgram()
	
	hud.HudButtonAddPressed.connect(ButtonAddPressed)
	hud.HudButtonSavePressed.connect(ButtonSavePressed)
	hud.HudButtonLoadPressed.connect(ButtonLoadPressed)
	#hud.PopupMenuClosed.connect(ClearFocus)
	hud.CreateLink.connect(CreateLink)
	hud.NewNote.connect(Duplicate)
	hud.OpenProjectRequested.connect(loadProject)
	hud.CreateProjectRequested.connect(createProject)


##################################################### PROJECT LIST
func clearWorkspace():
	noteList.clearNotesAndConnections()

func initProgram():
	ProjectList.clear()
	
	var dir = DirAccess.open("user://Projects")
	
	if (dir == null):
		dir = DirAccess.open("user://")
		dir.make_dir("./Projects")
		dir = DirAccess.open("user://Projects")
	
	var files = dir.get_files()
	printt(files)
	for line in files:
		if (line.right(3) == ".mg"):
			ProjectList.append(line)
	
	if (ProjectList.size() <= 0):
		OS.alert("Project list empty!")

func loadProject(projectName : String):
	clearWorkspace()
	
	setProjectName(projectName)
#	noteList.loadFromFile(projectName)
	
	noteList.readOnNextFrame = [true, projectName]



func createProject(projectName : String):
	clearWorkspace()
	setProjectName(projectName)

func updateProjectList():
	ProjectList.clear()
	
	var dir = DirAccess.open("user://Projects")
	
	if (dir == null):
		return
	
	var files = dir.get_files()
	printt(files)
	for line in files:
		if (line.right(3) == ".mg"):
			ProjectList.append(line)



##################################################### WINDOW BEHAVIOUR
func _notification(what):
	if (what == NOTIFICATION_WM_CLOSE_REQUEST):
		
		if (modified):
			## Stops the program from closing
			get_tree().set_auto_accept_quit(false)
			print("Close Request Notified (cancelling)")
			
			# Make GUI Question
			exitConfirmationDialog.popup_centered()
		else:
			get_tree().set_auto_accept_quit(true)


func _input(event):
	if (!hud.popupVisible && (event is InputEventKey || event is InputEventMouseButton)):
		setModified()

func setModified(_modified : bool = true):
	modified = _modified
	
	var _modifiedString = ""
	if (modified):
		_modifiedString = "* "
	
	setWindowName(_modifiedString + getWindowName())

func setProjectName(projectName : String):
	ProjectName = projectName
	setWindowName(ProjectName)

func getWindowName() -> String:
	return get_tree().root.get_window().title.replace(
		AppName, ""
	).replace("* ", "")

func setWindowName(newName : String):
	get_tree().root.get_window().title = (
		newName + AppName
	)



##################################################### HUD INTERACTIONS
func ButtonAddPressed():
	noteList.addNote()

func ButtonSavePressed():
	noteList.saveToFile()
	setModified(false)

func ButtonLoadPressed():
	noteList.loadFromFile()


###################################################### NOTE INTERACTIONS
func ClearFocus():
	grab_focus()

func CreateLink(note):
	noteList.connectionRequest(note)

func Duplicate(note : Note):
	var _note = noteList.addNoteFromContext(
		noteList.nextNoteUID, note.getText(), note.position, note.size, note.colour, false
	)
	
	_note.dragging = true


######################################################## GET / SETTERS
func getLastColour() -> Color:
	return lastColour

func getProjectName() -> String:
	return ProjectName

func getProjectList() -> Array:
	updateProjectList()
	return ProjectList


########################################################## SIGNALS
func _on_note_list_rmb_note(note):
	hud.changeTarget(note)
	hud.openRmbMenu()

#func _on_note_list_start_link(note):
#	hud.changeLinkTarget(note)
#	hud.startLink()

func _on_background_gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT):
		hud.changeTarget()


func _on_note_list_link_next_target_changed(note):
	hud.changeHoverNote(note)


