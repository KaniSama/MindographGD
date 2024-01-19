using Godot;
using Godot.Collections;

using System;
using System.Collections.Generic;
using System.Globalization;

public partial class Workspace : Control
{
	#region EssentialsAndConstants
		const string APPNAME = "                 [Mindograph]";
		int[] CURRENTVERSION = { 0, 0, 1, 3 };
		
		Godot.Collections.Dictionary <string, Variant> config = new Godot.Collections.Dictionary<string, Variant>() {
			["version"] = GetCurrentVersion(),
			["maximized"] = true,
			["windoww"] = 1280,
			["windowh"] = 720,
			["autosave"] = true,
			["autosavefreqmins"] = 5,
			["darkmode"] = false,
			["defaultcolor"] = GetLastColor(),
			["defaultlinkcolor"] = Colors.Red,
			["defaultfont"] = "default"
		};

		const string DIRPROXY = "user://";
		const string PROJDIRNAME = "Projects";
		const string CONFIGDIRNAME = "Config";
		const string CONFIGFILENAME = "config.json";

		string projectName = "!!untitled!!";
		List<string> projectList = new List<string>();
		bool modified = false;
	#endregion


	#region ClassVariables
		HUD hud; // onready -- $HUD
		NoteList noteList; // onready -- $NoteList

		TextureRect bgTexture; // onready -- $Background

		ConfirmationDialog exitConfirmationDialog; // onready -- $ExitConfirmationDialog
		Window appSettingsWindow; // onready -- $AppSettingsWindow
		Window replaceWindow; // onready -- $ReplaceWindow

		Timer autosaveTimer; // onready -- $AutosaveTimer
		Timer fpsResetTimer; // onready -- $FPSResetTimer

		UndoRedo undoStack = new UndoRedo();
		ulong undoStackVer; // onready -- undoStack.GetVersion();

		Color lastColor = Colors.Khaki;
	#endregion


	#region Overrides
		public override void _Ready()
		{
			// Setting onready variables
			hud = GetNode<HUD>("HUD");
			noteList = GetNode<NoteList>("NoteList");

			bgTexture = GetNode<TextureRect>("Background");

			exitConfirmationDialog = GetNode<ConfirmationDialog>("ExitConfirmationDialog");
			appSettingsWindow = GetNode<Window>("AppSettingsWindow");
			replaceWindow = GetNode<Window>("ReplaceWindow");

			autosaveTimer = GetNode<Timer>("AutosaveTimer");
			fpsResetTimer = GetNode<Timer>("FPSResetTimer");

			undoStackVer = undoStack.GetVersion();

			// Initializing the program's state
			InitializeApp();

			// Connect HUD signals
			hud.HudButtonAddPressed += (ButtonAddPressed);
			hud.HudButtonSavePressed += (ButtonSavePressed);
			hud.CreateLink += (CreateLink);
			hud.NewNote += (Duplicate);
			hud.OpenProjectRequested += (LoadProject);
			hud.CreateProjectRequested += (CreateProject);
			hud.OpenSettingsRequested += (OpenSettings);
			hud.OpenReplaceRequested += (OpenReplace);
			// Connect subwindow signals
			appSettingsWindow.UpdateConfig += (UpdateConfigFromSettings);
			replaceWindow.Confirm += (ReplaceTextInNotes);
			// Connect main window signals
			GetTree().Root.GetWindow().SizeChanged += (WindowResized);
		}

		public override void _Notification(int _what) {
			// Adds an Exit Confirmation Dialog Window
			// if the file's been modified
			if (_what == NotificationWMCloseRequest) {
				if (modified) {
					// Prevent the program from closing
					GetTree().SetAutoAcceptQuit(false);

					// Close subwindows
					OpenSettings(false);
					OpenReplace(false);

					// Make GUI question
					exitConfirmationDialog.PopupCentered();
				} else {
					GetTree().SetAutoAcceptQuit(true);
				}
			}
		}

		public override void _Input(InputEvent @event) {
			// Increase processor & gpu load when in use.
			// 'fpsResetTimer' reduces that load when firing.
			Engine.MaxFps = 0;
			fpsResetTimer.Start();

			if (!hud.IsPopupVisible() && (@event is InputEventKey || @event is InputEventMouse)) {
				/// TODO: UndoStack things !!! !!!
				//if (undoStack.GetVersion() != undoStackVer)
					SetModified();
			}
		}
	#endregion


	#region ProjectManagement
		// Nukes Workspace & Clears undo history!
		public void ClearWorkspace() {
			noteList.ClearNotesAndConnections();
			undoStack.ClearHistory(false);
		}

		public void InitializeApp() {
			projectList.Clear();

			// Create Config directory
			using var _dir = DirAccess.Open(DIRPROXY + CONFIGDIRNAME);

			if (_dir == null) {
				_dir = DirAccess.Open(DIRPROXY);
				_dir.MakeDir("./" + CONFIGDIRNAME);
				_dir = DirAccess.Open(DIRPROXY + CONFIGDIRNAME);
			}

			// Create Config file
			FileAccess _configFile;
			string _configFileName = DIRPROXY + CONFIGDIRNAME + "/" + CONFIGFILENAME;

			if (!_dir.FileExists(_configFileName)) {
				_configFile = FileAccess.Open(_configFileName, FileAccess.ModeFlags.Write);

				_configFile.StoreLine(Json.Stringify(config,"\t",false,true));

				_configFile.Flush();
				_configFile.Close();
			}

			// Load Config JSON
			_configFile = FileAccess.Open(_configFileName, FileAccess.ModeFlags.Read);

			string _configString = "";
			while (!_configFile.EofReached()) {
				_configString += _configFile.GetLine().Replace("\n", "");
			}

			Godot.Collections.Dictionary _config = Json.ParseString(_configString).AsGodotDictionary();

			foreach (string __i in _config.Keys) {
				config[__i] = _config[__i];
			}
			config["version"] = GetCurrentVersion();

			// Convert color from file (string) to Color()
			string __defColor = (string)config["defaultcolor"];
			string[] _colorToArray = __defColor.Replace("(","").Replace(")","").Split(",");
			List<float> _colorValues = new List<float>();

			foreach (string __i in _colorToArray) {
				_colorValues.Add(float.Parse(__i, CultureInfo.InvariantCulture));
			}

			Color _newDefaultColor = new Color(
				_colorValues[0],
				_colorValues[1],
				_colorValues[2],
				_colorValues[3]
			);
			config["defaultcolor"] = _newDefaultColor;

			// Set other App-wide variables from config
			Window _window = GetTree().Root.GetWindow();
			if (config["maximized"].As(bool))
				_window.SetMode(Window.ModeMaximized);
			else
				_window.Size = new Vector2((float)config["windoww"], (float)config["windowh"]);

			appSettingsWindow.SetAutosave(config["autosave"], true);
			appSettingsWindow.SetAutosaveFrequency(config["autosavefreqmins"], true);
			appSettingsWindow.SetDarkMode(config["darkmode"], true);
			bgTexture.Visible = !config["darkmode"];
			appSettingsWindow.SetDefaultColor(config["defaultcolor"]);
			SetLastColor(config["defaultcolor"]);

			UpdateConfigFromSettings("autosave", config["autosave"]);
			UpdateConfigFromSettings("darkmode", config["darkmode"]);


			// Create Projects directory
			_dir = DirAccess.Open(DIRPROXY + PROJDIRNAME);

			if (_dir == null) {
				_dir = DirAccess.Open(DIRPROXY);
				_dir.MakeDir("./" + PROJDIRNAME);

				_dir = DirAccess.Open(DIRPROXY + PROJDIRNAME);
			}

			// Get files in Projects directory
			//  and add them to the projectList
			string[] _files = _dir.GetFiles();

			foreach (string __line in _files) {
				if (__line.Substring(__line.Length - 3) == ".mg")
					projectList.Append(__line);
			}
		}


		public void LoadProject(string _projectName) {
			ClearWorkspace();
			SetProjectName(_projectName);
			noteList.readOnNextFrame = new NoteList.ReadOnNextFrame(true, _projectName);
		}

		public void CreateProject(string _projectName) {
			ClearWorkspace();
			SetProjectName(_projectName);
		}

		public void UpdateProjectList() {
			projectList.Clear();

			using var _dir = DirAccess.Open(DIRPROXY + PROJDIRNAME);

			if (_dir == null) return;

			string[] _files = _dir.GetFiles();
			foreach (string __line in _files) {
				if (__line.Substring(__line.Length-3) == ".mg")
					projectList.Append(__line);
			}
		}
	#endregion
}
