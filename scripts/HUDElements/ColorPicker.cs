using Godot;
using System;

public partial class ColorPicker : Godot.ColorPicker
{
	public override void _Ready()
	{
		Position.X = GetParent().Size.X * .5f - Size.X * .5f;
		Position.Y = 16;
	}
}
