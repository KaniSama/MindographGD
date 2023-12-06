using Godot;
using System;
using System.Collections.Generic;

public partial class FPSCounter : Label
{
	// Timestamps of frames rendered in the last second
	List<int> times = new List<int>();
	
	int fps = 0;

	public override void _Ready()
	{
		int _now = Time.GetTicksMsec();

		// Remove frames older than 1 second in the 'times' list
		while (times.Count() > 0 && times[0] <= _now - 1000)
			times.RemoveAt(0);

		times.Add(_now);
		fps = times.Count();

		// Display FPS in the label
		Text = "" + fps + " FPS";
	}

	public override void _Input(InputEvent @event)
	{
		if (@event.IsActionPressed("debug"))
			Visible = !Visible;
	}
}
