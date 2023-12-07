using Godot;
using System;
using System.Collections.Generic;

public partial class Workspace : Control
{
	const string APPNAME = "                 [Mindograph]";
	int[] CURRENTVERSION = { 0, 0, 1, 3 };

	Dictionary <string, Variant> config = new Dictionary<string, Variant>() {
		["version"] = GetCurrentVersion(),
		["maximized"] = true,
		["windoww"] = 1280,
		["windowh"] = 720,
		["autosave"] = true,
		["autosavefreqmins"] = 5,
		["darkmode"] = false,
		["defaultcolor"] = GetLastColor(),
		["defaultlinkcolor"] = Color.Red,
		["defaultfont"] = "default"
	};

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
}
