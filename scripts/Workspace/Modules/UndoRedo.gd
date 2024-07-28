extends Node

@onready var Stack : UndoRedo = UndoRedo.new()


########################################### OVERRIDES
func _____OVERRIDES(): pass


func _input(event):
	if event.is_action_pressed("global_undo"):
		undo()
	elif event.is_action_pressed("global_redo"):
		redo()



########################################### HELPER FUNCTIONS
func _____HELPERS(): pass


func clear_history(increase_version):
	Stack.clear_history(increase_version)

func register_action(do_stack : Array [ Callable ], undo_stack : Array [ Callable ], action_name : String):
	Stack.create_action(action_name)
	for __i : Callable in do_stack:
		Stack.add_do_method(__i)
	for __i : Callable in undo_stack:
		Stack.add_undo_method(__i)
	Stack.commit_action()

func undo():
	if Stack.has_undo():
		Stack.undo()

func redo():
	if Stack.has_redo():
		Stack.redo()



########################################### SIGNALS
func _____SIGNALS(): pass


func _on_child_key_pressed():
	pass
