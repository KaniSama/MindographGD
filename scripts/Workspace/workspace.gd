extends Control
class_name Workspace

const AppName = "                 [Mindograph]"
const CurrentVersion = [0, 0, 1, 0]

var Config : Dictionary = {}
const ConfigFileLocation = "user://Config/config.json"

var ProjectName : String = "NewMindographProject.mg"
var ProjectList : Array = []
var Modified : bool = false

@onready var hud : Node = $HUD
@onready var noteList : Node = $NoteList

@onready var exitConfirmationDialog = $ExitConfirmationDialog
@onready var appSettingsWindow = $AppSettingsWindow

var lastColour: Color = Color.KHAKI


func _ready():
	
	## Initiates the program's state,
	## including creating necessary folders if it's being run for the first time
	initProgram()
	
	## Connect to the HUD object's signals
	hud.HudButtonAddPressed.connect(ButtonAddPressed)
	hud.HudButtonSavePressed.connect(ButtonSavePressed)
	hud.HudButtonLoadPressed.connect(ButtonLoadPressed)
	hud.CreateLink.connect(CreateLink)
	hud.NewNote.connect(Duplicate)
	hud.OpenProjectRequested.connect(loadProject)
	hud.CreateProjectRequested.connect(createProject)
	hud.OpenSettingsRequested.connect(OpenSettings)


##################################################### PROJECT LIST
func clearWorkspace():
	noteList.clearNotesAndConnections()

func initProgram():
	
	ProjectList.clear()
	
	# Create the Projects directory
	var dir = DirAccess.open("user://Projects")
	
	if (dir == null):
		dir = DirAccess.open("user://")
		dir.make_dir("./Projects")
		dir = DirAccess.open("user://Projects")
	
	# Get files in Projects directory
	var files = dir.get_files()
	printt(files)
	for line in files:
		if (line.right(3) == ".mg"):
			ProjectList.append(line)
	
	if (ProjectList.size() <= 0):
		OS.alert("Project list empty!")
	
	
	# Create the config directory
	dir = DirAccess.open("user://Config")
	
	if (dir == null):
		dir = DirAccess.open("user://")
		dir.make_dir("./Config")
		dir = DirAccess.open("user://Config")
	
	# Create config file
	var configFileName = ConfigFileLocation
	var configFile : FileAccess
	
	if (!dir.file_exists(configFileName)):
		configFile = FileAccess.open(configFileName, FileAccess.WRITE)
		
		var config : Dictionary = {
			"version" : getCurrentVersion(),
			"maximized" : true,
			"autosave" : true,
			"autosavefreqmins" : 5,
			"defaultcolour" : getLastColour(),
			"defaultfont" : "default"
		}
		configFile.store_line(JSON.stringify(config,"\t",false,true))
		
		configFile.flush()
		configFile.close()
	
	# Load config file into a dictionary
	configFile = FileAccess.open(configFileName, FileAccess.READ)
	
	var configString = ""
	while (!configFile.eof_reached()):
		configString += configFile.get_line().replace("\n", "")
	
	var config : Dictionary = JSON.parse_string(configString)
	
	Config = config
	print(Config)

#	appSettingsWindow.setAutosave(bool(Config["autosave"]))
#	appSettingsWindow.setAutosaveFrequency(int(Config["autosavefreqmins"]))

func loadProject(_project_name : String):
	clearWorkspace()
	
	setProjectName(_project_name)
#	noteList.loadFromFile(projectName)
	
	noteList.readOnNextFrame = [true, _project_name]



func createProject(_project_name : String):
	clearWorkspace()
	setProjectName(_project_name)

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
		
		if (Modified):
			## Stops the program from closing
			get_tree().set_auto_accept_quit(false)
			print("Close Request Notified (cancelling)")
			
			# Close AppSettings window
			CloseSettings()
			
			# Make GUI Question
			exitConfirmationDialog.popup_centered()
		else:
			get_tree().set_auto_accept_quit(true)


func _input(event):
	if (!hud.getPopupVisible() && (event is InputEventKey || event is InputEventMouseButton)):
		setModified()

func setModified(_modified : bool = true):
	Modified = _modified
	
	var _modifiedString = ""
	if (Modified):
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


func OpenSettings():
	appSettingsWindow.popup_centered()

func CloseSettings():
	appSettingsWindow.hide()


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
	_note.offset = -Vector2(_note.size.x * .5, 8)



######################################################## HELPERS
func strToVersion(string : String) -> Array:
	var _version_strs = string.strip_edges().replacen("v", "").split(".")
	var _version_ints = []
	
	for i in _version_strs:
		_version_ints.append(int(i))
	
	return _version_ints

## Returns 1 if Version1 > Version2,
## 2 if Version2 > Version1,
## or 0 if they're the same.
func compareVersions(_v1, _v2) -> int:
	if (_v1 is String):
		_v1 = strToVersion(_v1)
	if (_v2 is String):
		_v2 = strToVersion(_v2)
	
	var _result = 0
	
	for i in range(4):
		if (_v1[i] > _v2[i]):
			_result = 1
			break
		if (_v2[i] > _v1[i]):
			_result = 2
			break
	
	return _result


func saveConfigToFile(config : Dictionary = Config):
	var configFile = FileAccess.open(ConfigFileLocation, FileAccess.WRITE)
	configFile.store_line(JSON.stringify(config,"\t",false,true))
	configFile.flush()
	configFile.close()


######################################################## GET / SETTERS
func getLastColour() -> Color:
	return lastColour

func getProjectName() -> String:
	return ProjectName

func getProjectList() -> Array:
	updateProjectList()
	return ProjectList


func getCurrentVersion() -> String:
	var _version = "v"
	for i in range(0, CurrentVersion.size(), 1):
		if (i != CurrentVersion.size()-1):
			_version += str(CurrentVersion[i]) + "."
		else:
			_version += str(CurrentVersion[i])
	return _version


func setLastColour(newColour : Color):
	lastColour = newColour


func setConfigKey(key : String, value : Variant):
	Config[key] = value
	
	## Save the config file
	saveConfigToFile(Config)


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


