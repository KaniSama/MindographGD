using Godot;
using System;

public partial class LinkDrawer : Control
{
	// Class Variables
	HUD parent; // onready -- $..
	Control linkDrawerEnd; // onready -- $../LinkDrawer


	public override void _Ready() {
		parent = (HUD)GetParent();
		linkDrawerEnd = parent.GetNode<Control>("LinkDrawer");
	}

	public override void _Draw() {
		if (linkDrawerEnd.Visible)
			DrawDashedLine(
				parent.GetLinkTarget().GetPinPosition() - Position,
				linkDrawerEnd.Position - Position,
				new Color(1f, 0f, 0f, .7f),
				3, 5, false
			);
	}

	public override void _Process(double delta)
	{
		if (linkDrawerEnd.Visible) {
			Position = FindParent("Workspace").GetNode<Camera2D>("Camera2D").Position;
			linkDrawerEnd.Position = GetGlobalMousePosition();
		}

		QueueRedraw();
	}


	public void OnLinkDrawerEndVisibilityChanged() {
		QueueRedraw();
	}
}
