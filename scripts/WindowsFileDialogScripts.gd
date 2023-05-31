var fileSaveScript = [
	"Add-Type -AssemblyName System.Windows.Forms",
	"$FileBrowser = New-Object System.Windows.Forms.SaveFileDialog",
	"$FileBrowser.filter = \"Mindograph File (.mg)| *.mg\"",
	"[void]$FileBrowser.ShowDialog()",
	"$FileBrowser.FileName"
]
var fileLoadScript = [
	"Add-Type -AssemblyName System.Windows.Forms",
	"$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog",
	"$FileBrowser.filter = \"Mindograph File (.mg)| *.mg\"",
	"[void]$FileBrowser.ShowDialog()",
	"$FileBrowser.FileName"
]

# Give it an Array of valid PS commands
func exec_script(ps_script : Array) -> Array:

	# Set file path
	var dir = DirAccess.open("user://")
	var path = ProjectSettings.globalize_path(dir.get_current_dir())

	# Create the PS-File
	var save_file = FileAccess.open(path + "MindographGodotPSScriptTemp.ps1", FileAccess.WRITE)

	for line in ps_script:
		save_file.store_line(line)

	save_file.flush()
	save_file.close()

	# Execute PowerShell script
	var output = []
	OS.execute("powershell.exe", ["-ExecutionPolicy", "Bypass", "-File", path + "/MindographGodotPSScriptTemp.ps1"], output, true, false)

	# Try remove the \r\n from output string (does not work for some reason)
	for i in output:
		i = i.strip_edges()

	# Remove the script for cleanliness reasons
	dir.remove(path + "/MindographGodotPSScriptTemp.ps1")

	return output
