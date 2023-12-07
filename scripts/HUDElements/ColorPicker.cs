using Godot;
using System;

public partial class ColorPicker : Godot.ColorPicker
{
	public override void _Ready()
	{
		Panel _parent = GetNode<Panel>("../");
		Position = new Vector2(
			_parent.Size.X * .5f - Size.X * .5f,
			16
		);
	}
}
