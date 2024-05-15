class_name SaveLoadSystem
extends Node


########################################### OVERRIDES
#func _____OVERRIDES(): pass



########################################### HELPER FUNCTIONS
func _____MAIN(): pass


func save_project(project_data : Dictionary) -> void:
	var project_name = project_data["project_name"]
	
	var file_name : String = "user://Projects/" + project_name.replacen(".mgx", "") + ".mgx"
	var file = FileAccess.open(
		file_name,
		FileAccess.WRITE
	)
	
	if (file == null):
		OS.alert("Unable to open file " + ProjectSettings.globalize_path(file_name))
		return
	
	## Save Parameters
	
	## Project data
	#MAYBE:
	#for __i in project_data.keys():
		#if project_data[__i] is Callable:
			#project_data[__i].call()
			#continue
		#
		## Store KEY first, then VALUE
		#file.store_var(__i)
		#file.store_var(project_data[__i])
	
	file.store_var(project_data)
	
	file.close()
	
	return

func load_project(project_name : String) -> Dictionary:
	var _project_data : Dictionary = {}
	
	var file_name : String = "user://Projects/" + project_name.replacen(".mgx", "") + ".mgx"
	var file = FileAccess.open(
		file_name,
		FileAccess.READ
	)
	
	if (file == null):
		OS.alert("Unable to open file " + ProjectSettings.globalize_path(file_name))
		return {}
	
	#MAYBE:
	#while not file.eof_reached():
		#var __key = file.get_var()
		#var __value = file.get_var()
		#_project_data[__key] = __value
	
	_project_data = file.get_var()
	
	file.close()
	
	return _project_data



########################################### SIGNALS
func _____SIGNALS(): pass


func _on_child_key_pressed():
	pass
