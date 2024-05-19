extends Window


signal UpdateConfig(key : String, value)


@onready var versionLabel = $BG/GridContainer/CurrentVersion
@onready var autosave = $BG/GridContainer/Autosave
@onready var autosaveFrequency = $BG/GridContainer/AutosaveFreq
@onready var defaultColor = $BG/GridContainer/DefaultNoteColor
@onready var darkMode = $BG/GridContainer/DarkMode

########################################### OVERRIDES
func _____OVERRIDES()->void:pass


func _ready() -> void:
	var currentVersion = get_parent().getCurrentVersion()
	
	versionLabel.text += currentVersion


########################################### HELPER FUNCTIONS
########################################### GET SETTERS
func _____GET_SETTERS()->void:pass


## If _emit_signal is true, these values will save to the config.json file
func setAutosave(_value : bool = true, _emit_signal : bool = true) -> void:
	if (_emit_signal):
		autosave.set_pressed(_value)
	else:
		autosave.set_pressed_no_signal(_value)

func setAutosaveFrequency(_value : int, _emit_signal : bool = true) -> void:
	if (_emit_signal):
		autosaveFrequency.set_value(_value)
	else:
		autosaveFrequency.set_value_no_signal(_value)

func setDarkMode(_value : bool = true, _emit_signal : bool = true) -> void:
	if (_emit_signal):
		darkMode.set_pressed(_value)
	else:
		darkMode.set_pressed_no_signal(_value)

func setDefaultColor(_value : Color) -> void:
	defaultColor.color = _value



########################################### SIGNALS
func _____SIGNALS():pass


func _on_about_to_popup():
	#find_child("DefaultNoteColor").color = get_parent().getLastColor()
	pass

func _on_close_requested():
	hide()



func _on_update_button_pressed():
	var HTTPrequester = HTTPRequest.new()
	add_child(HTTPrequester)
	HTTPrequester.name = "HTTPrequester"
	
	HTTPrequester.request_completed.connect(_on_request_completed)
	
	HTTPrequester.request("https://api.github.com/repos/KaniSama/MindographGD/releases/latest")

func _on_request_completed(result, response_code, _headers, body):
	
	if (result != OK || response_code != 200):
		return
	
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	var currentVersion = get_parent().getCurrentVersion()
	match (get_parent().compareVersions(currentVersion, json["name"])):
		0:
			OS.alert("You are using the latest version! Good job!")
		1:
			OS.alert("Somehow you're using an unreleased version! Better be careful! :)")
		2:
			OS.alert("Version " + json["name"] + " available! \nOpening browser...")
			OS.shell_open("https://github.com/KaniSama/MindographGD/releases/latest")
	
	var HTTPrequester = find_child("HTTPrequester")
	if (HTTPrequester != null):
		HTTPrequester.queue_free()



func _on_autosave_toggled(toggled_on):
	emit_signal("UpdateConfig", "autosave", toggled_on)

func _on_autosave_freq_value_changed(value):
	emit_signal("UpdateConfig", "autosavefreqmins", value)

func _on_dark_mode_toggled(toggled_on):
	emit_signal("UpdateConfig", "darkmode", toggled_on)

func _on_default_note_color_color_changed(color):
	emit_signal("UpdateConfig", "defaultcolor", color)





func _on_open_projects_button_pressed():
	OS.shell_open(ProjectSettings.globalize_path("user://Projects"))

func _on_open_config_button_pressed():
	OS.shell_open(ProjectSettings.globalize_path("user://Config/config.json"))


func _on_leave_feedback_button_pressed():
	OS.alert("Opening browser...")
	OS.shell_open("https://forms.gle/B3nivEanm7JRiSF89")


