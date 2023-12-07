using Godot;
using System;
using System.Collections.Generic;

public partial class LinkDrawer : Control
{
	Control noteList; // onready -- $../NoteList
	Camera2D camera; // onready -- $../Camera2D
	
	public override void _Ready()
	{
		noteList = GetNode<Control>("../NoteList");
		camera = GetNode<Camera2D>("../Camera2D");
	}

	public override void _Draw() {
		List<Note[]> _connections = noteList.GetConnections();

		if (_connections.Length <= 0)
			return;
		
		foreach (Note[] __i in _connections) {
			Note __note1 = __i[0];
			Note __note2 = __i[1];

			if (GodotObject.IsInstanceValid(__note1) && GodotObject.IsInstanceValid(__note2)) {
				if (IntersectsViewport(__note1.GetRect())
					|| (IntersectsViewport(__note2.GetRect()))
				) {
					DrawLine(
						__note1.GetPinPosition() - Position,
						__note2.GetPinPosition() - Position,
						Color(1, 0, 0, .7),
						3,
						false
					);
				}
			} else {
				noteList.EraseConnection(__i);
			}
		}
	}

	public override void _Process(double delta)
	{
		Position = camera.Position;
		QueueRedraw();
	}


	// Helper functions
	public bool IntersectsViewport(Rect2 _rect) {
		Transform2D _transform = GetCanvasTransform();
		Vector2 _scale = transform.GetScale();

		return new Rect2(-transform.Origin / _scale, GetViewportRect().Size / _scale).Intersects(_rect);
	}
}
