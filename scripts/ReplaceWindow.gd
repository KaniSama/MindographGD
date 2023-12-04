extends Window

signal Confirm(_what : String, _forWhat : String, _whole : bool, _ignoreCase : bool)

@onready var what = $PanelContainer/ReplacerContainer/What
@onready var forWhat = $PanelContainer/ReplacerContainer/ForWhat
@onready var whole = $PanelContainer/ReplacerContainer/FullWords
@onready var ignoreCase = $PanelContainer/ReplacerContainer/IgnoreCase



########################################### OVERRIDES


########################################### HELPER FUNCTIONS


########################################### SIGNALS

func _on_ok_button_pressed():
	emit_signal(
		"Confirm", 
		what.text.strip_edges(), 
		forWhat.text.strip_edges(), 
		whole.button_pressed, 
		ignoreCase.button_pressed
	)
	
	hide()

func _on_close_requested():
	hide()
