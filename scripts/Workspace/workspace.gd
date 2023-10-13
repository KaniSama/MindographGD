extends Control
class_name Workspace

const AppName = "                 [Mindograph]"
const CurrentVersion = [0, 0, 2, 0]

@onready var Config : Dictionary = {
	"version" : getCurrentVersion(),
	"maximized" : true,
	"windoww" : 1280,
	"windowh" : 720,
	"autosave" : true,
	"autosavefreqmins" : 5,
	"defaultcolour" : getLastColour(),
	"defaultlinkcolour": Color.RED,
	"defaultfont" : "default"
}
const ConfigFileLocation = "user://Config/config.json"

var ProjectName : String = "!!untitled!!"
var ProjectList : Array = []
var Modified : bool = false

@onready var hud : Node = $HUD
@onready var noteList : Node = $NoteList

@onready var exitConfirmationDialog : ConfirmationDialog = $ExitConfirmationDialog
@onready var appSettingsWindow : Window = $AppSettingsWindow
@onready var replaceWindow : Window = $ReplaceWindow

@onready var autosaveTimer = $AutosaveTimer
@onready var fpsResetTimer = $FPSResetTimer

var lastColour: Color = Color.KHAKI



##################################################### OVERRIDES
func _____OVERRIDES():pass


func _ready():
	
	OS.low_processor_usage_mode = true
	
	## Initiates the program's state,
	## including creating necessary folders if it's being run for the first time
	initProgram()
	
	## Connect to the HUD object's signals
	hud.HudButtonAddPressed.connect(ButtonAddPressed)
	hud.HudButtonSavePressed.connect(ButtonSavePressed)
#	hud.HudButtonLoadPressed.connect(ButtonLoadPressed)
	hud.CreateLink.connect(CreateLink)
	hud.NewNote.connect(Duplicate)
	hud.OpenProjectRequested.connect(loadProject)
	hud.CreateProjectRequested.connect(createProject)
	hud.OpenSettingsRequested.connect(OpenSettings)
	hud.OpenReplaceRequested.connect(OpenReplace)
	
	## Connect to the subwindow objects's signals
	appSettingsWindow.UpdateConfig.connect(UpdateConfigFromSettings)
	replaceWindow.Confirm.connect(ReplaceTextInNotes)
	
	## Connect to the main window's signals
	get_tree().root.get_window().size_changed.connect(WindowResized)


func _notification(what):
	if (what == NOTIFICATION_WM_CLOSE_REQUEST):
		
		if (Modified):
			## Stops the program from closing
			get_tree().set_auto_accept_quit(false)
			
			# Close AppSettings window
			CloseSettings()
			
			# Make GUI Question
			exitConfirmationDialog.popup_centered()
		else:
			get_tree().set_auto_accept_quit(true)


func _input(event):
	Engine.max_fps = 0
	fpsResetTimer.start()
	
	
	if (!hud.getPopupVisible() && (event is InputEventKey || event is InputEventMouseButton)):
		setModified()




##################################################### PROJECT MANAGEMENT
func _____PROJECT_MANAGEMENT():pass


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
	var _configFileName = ConfigFileLocation
	var _configFile : FileAccess
	
	if (!dir.file_exists(_configFileName)):
		_configFile = FileAccess.open(_configFileName, FileAccess.WRITE)
		
		_configFile.store_line(JSON.stringify(Config,"\t",false,true))
		
		_configFile.flush()
		_configFile.close()
	
	
	# Load config file into a single JSON string
	_configFile = FileAccess.open(_configFileName, FileAccess.READ)
	
	var _configString = ""
	while (!_configFile.eof_reached()):
		_configString += _configFile.get_line().replace("\n", "")
	
	# Read config JSON and set variables
	# ! Does not set variables that aren't in the file !
	var _config : Dictionary = JSON.parse_string(_configString)
	
	for __i in _config.keys():
		Config[__i] = _config[__i]
	#Config = _config
	Config["version"] = getCurrentVersion()
	
	
	# convert a String gotten from the text file into Color
	var _colourToArray = Config["defaultcolour"].replace("(","").replace(")","").split(",")
	var _colourArray = []
	for i in _colourToArray:
		_colourArray.append(float(i))
	var _newDefaultColour = Color(_colourArray[0], _colourArray[1], _colourArray[2], _colourArray[3])
	Config["defaultcolour"] = _newDefaultColour
	
	# Read the config and set the variables
	var _window = get_tree().root.get_window()
	if (Config["maximized"]):
		_window.set_mode(Window.MODE_MAXIMIZED)
	else:
		_window.size = Vector2(Config["windoww"], Config["windowh"])
	
	appSettingsWindow.setAutosave(Config["autosave"], true)
	appSettingsWindow.setAutosaveFrequency(Config["autosavefreqmins"], true)
	appSettingsWindow.setDefaultColour(Config["defaultcolour"])
	setLastColour(Config["defaultcolour"])
	
	UpdateConfigFromSettings("autosave", Config["autosave"])

func loadProject(_project_name : String):
	clearWorkspace()
	
	setProjectName(_project_name)
	
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
	for line in files:
		if (line.right(3) == ".mg"):
			ProjectList.append(line)



##################################################### WINDOW BEHAVIOUR
func _____WINDOW_SETTERS():pass

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


func setModified(_modified : bool = true):
	Modified = _modified
	
	var _modifiedString = ""
	if (Modified):
		_modifiedString = "* "
	
	setWindowName(_modifiedString + getWindowName())


func OpenSettings():
	appSettingsWindow.popup_centered()

func CloseSettings():
	appSettingsWindow.hide()


func OpenReplace():
	replaceWindow.popup_centered()

func CloseReplace():
	replaceWindow.hide()


func WindowResized():
	var window = get_tree().root.get_window()
	
	UpdateConfigFromSettings("windoww", window.size.x)
	UpdateConfigFromSettings("windowh", window.size.y)
	
	if (window.mode == Window.MODE_MAXIMIZED):
		UpdateConfigFromSettings("maximized", true)
	else:
		UpdateConfigFromSettings("maximized", false)



##################################################### HUD INTERACTIONS
func _____HUD_SIGNALS():pass

func ButtonAddPressed():
	noteList.addNote()

func ButtonSavePressed():
	noteList.saveToFile()
	setModified(false)

#func ButtonLoadPressed():
#	noteList.readOnNextFrame = [true, ProjectName]
#	noteList.loadFromFile()


###################################################### NOTE INTERACTIONS
func _____NOTE_INTERACTIONS():pass

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

func ReplaceTextInNotes(_what : String, _forWhat : String, _whole : bool, _ignoreCase : bool):
	_what = _what.strip_edges()
	_forWhat = _forWhat.strip_edges()
	
	var _notesChanged = noteList.replaceTextInNotes(_what, _forWhat, _whole, _ignoreCase)
	
	OS.alert(str(_notesChanged) + " notes changed! :)")




######################################################## TIMER INTERACTIONS
func _____TIMER_INTERACTIONS():pass

func startAutosaveTimer(_seconds : int = 60):
	autosaveTimer.start(_seconds)

func stopAutosaveTimer():
	autosaveTimer.stop()


######################################################## HELPERS
func _____HELPERS():pass

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


func UpdateConfigFromSettings(_key : String, _value : Variant):
	setConfigKey(_key, _value)
	
	if (_key == "defaultcolour" && _value is Color):
		setLastColour(_value)
	
	if (_key == "autosave" && _value || _key == "autosavefreqmins" && _value != 0 && Config["autosave"]):
		startAutosaveTimer(Config["autosavefreqmins"] * 60)
	elif (_key == "autosave" && !_value || _key == "autosavefreqmins" && _value == 0):
		stopAutosaveTimer()

func saveConfigToFile(config : Dictionary = Config):
	var configFile = FileAccess.open(ConfigFileLocation, FileAccess.WRITE)
	configFile.store_line(JSON.stringify(config,"\t",false,true))
	configFile.flush()
	configFile.close()


######################################################## GET / SETTERS
func _____GET_SETTERS():pass

func getLastColour() -> Color:
	return lastColour

func setLastColour(newColour : Color):
	lastColour = newColour


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


func getTimeTillAutosave() -> int:
	return autosaveTimer.time_left


func getConfigKey(_value : Variant) -> String:
	return Config.find_key(_value)

func setConfigKey(key : String, value : Variant):
	Config[key] = value
	
	## Save the config file
	saveConfigToFile(Config)


########################################################## SIGNALS
func _____SIGNALS():pass

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



func _on_autosave_timer_timeout():
	if (getProjectName() != "!!untitled!!"):
		noteList.saveToFile()

func _on_fps_reset_timer_timeout():
	Engine.max_fps = 15
