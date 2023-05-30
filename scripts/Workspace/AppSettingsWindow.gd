extends Window

@onready var versionLabel = $BG/GridContainer/CurrentVersion
@onready var autosave = $BG/GridContainer/Autosave
@onready var autosaveFrequency = $BG/GridContainer/AutosaveFreq


########################################### OVERRIDES

func _ready():
	var currentVersion = get_parent().getCurrentVersion()
	
	versionLabel.text += currentVersion


########################################### HELPER FUNCTIONS
########################################### GET SETTERS

## If _emit_signal is true, these values will save to the config.json file
func setAutosave(_value : bool = true, _emit_signal : bool = true):
	if (_emit_signal):
		autosave.set_pressed(_value)
	else:
		autosave.set_pressed_no_signal(_value)

func setAutosaveFrequency(_value : int, _emit_signal : bool = true):
	if (_emit_signal):
		autosaveFrequency.set_value(_value)
	else:
		autosaveFrequency.set_value_no_signal(_value)


########################################### SIGNALS

func _on_about_to_popup():
	find_child("DefaultNoteColour").color = get_parent().getLastColour()

func _on_close_requested():
	hide()



func _on_update_button_pressed():
	var HTTPrequester = HTTPRequest.new()
	add_child(HTTPrequester)
	HTTPrequester.name = "HTTPrequester"
	
	HTTPrequester.request_completed.connect(_on_request_completed)
	
	HTTPrequester.request("https://api.github.com/repos/KaniSama/MindographGD/releases/latest")

func _on_request_completed(result, response_code, headers, body):
	
	if (result != OK || response_code != 200):
		return
	
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	var currentVersion = get_parent().getCurrentVersion()
	match (get_parent().compareVersions(currentVersion, json["name"])):
		0:
			OS.alert("You are using the latest version! Good job!")
		1:
			OS.alert("Somehow you're using an unreleased version! HOW")
		2:
			OS.alert("Version " + json["name"] + " available! \nOpening browser...")
			OS.shell_open("https://github.com/KaniSama/MindographGD/releases/latest")
	
	var HTTPrequester = find_child("HTTPrequester")
	if (HTTPrequester != null):
		HTTPrequester.queue_free()
