extends Window

@onready var versionLabel = $BG/GridContainer/CurrentVersion


########################################### OVERRIDES

func _ready():
	var currentVersion = get_parent().getCurrentVersion()
	
	versionLabel.text += currentVersion


########################################### HELPER FUNCTIONS

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
	
	if (result != 0 || response_code != 200):
		return
	
	#rintt(result, response_code, headers, body)
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	var currentVersion = get_parent().getCurrentVersion()
	if (currentVersion != json["name"]):
		OS.alert("Version " + json["name"] + " available! \nOpening browser...")
		OS.shell_open("https://github.com/KaniSama/MindographGD/releases/latest")
	
	var HTTPrequester = find_child("HTTPrequester")
	if (HTTPrequester != null):
		HTTPrequester.queue_free()
