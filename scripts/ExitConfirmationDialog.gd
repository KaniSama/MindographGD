extends ConfirmationDialog

@onready var buttonSave : Button

func _ready():
	buttonSave = add_button("Save right now!", true, "SaveNow")

func _on_confirmed():
	get_tree().quit()

func _on_custom_action(action):
	if (action == "SaveNow"):
		get_parent().ButtonSavePressed()
		remove_button(buttonSave)
		title = "Saved!"
		get_ok_button().text = "Exit"
