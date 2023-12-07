using Godot;
using System;

public partial class AutosaveTimerLabel : Label
{
	string initText;

	public override void _Ready()
	{
		initText = Text;
	}

	public override void _Process(double delta)
	{
		int _time = (FindParent("Workspace") as Workspace).GetTimeTillAutosave();

		Text = initText + _time;
	}

	public override void _Input(InputEvent @event) {
		if (@event.IsActionPressed("debug"))
			Visible = !Visible;
	}
}
