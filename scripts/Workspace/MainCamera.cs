using Godot;
using System;

public partial class MainCamera : Camera2D
{
	#region ClassVariables
		TextureRect BG;
		Vector2 GRIDSIZE;
		Vector2 gridPosition;
		Vector2 BGPositionCenter;

		Vector2 grab;
		bool grabbed = false;

		Vector2 unzoomPosition;
		bool unzooming = false;
	#endregion


	#region Overrides
		public override void _Ready()
		{
			BG = GetParent().GetNode<TextureRect>("Background");
			gridPosition = new Vector2(0f,0f);
			GRIDSIZE = BG.Texture.GetSize();
			BGPositionCenter = new Vector2(BG.Size.X * .5f, BG.Size.Y * .5f);
		}

		public override void _Process(double delta)
		{
			// Camera dragging & BG scrolling
			if (Input.IsActionJustPressed("mmb")) {
				grabbed = true;
				grab = GetGlobalMousePosition();
			}

			if (grabbed) {
				Position += grab - GetGlobalMousePosition();

				gridPosition.X = Mathf.Round(Position.X / GRIDSIZE.X);
				gridPosition.Y = Mathf.Round(Position.Y / GRIDSIZE.Y);

				BG.Position = gridPosition * GRIDSIZE - GRIDSIZE - BGPositionCenter;


				if (Input.IsActionPressed("mmb")) {
					// Warp mouse if dragging outside the workspace
					Vector2 _mouse = GetViewport().GetMousePosition();
					Vector2 _size = GetViewportRect().Size;

					Vector2 _padding = new Vector2(5f, 5f);
					Vector2 _paddingSm = _padding * .5f;
					bool _regrab = false;

					if (_mouse.X > _size.X - _paddingSm.X) {
						_regrab = true;
						GetViewport().WarpMouse(new Vector2(_mouse.X - _size.X + _padding.X, _mouse.Y));
					}
					else if (_mouse.X < 0 + _paddingSm.X) {
						_regrab = true;
						GetViewport().WarpMouse(new Vector2(_mouse.X + _size.X - _padding.X, _mouse.Y));
					}
					
					if (_mouse.Y > _size.Y - _paddingSm.Y) {
						_regrab = true;
						GetViewport().WarpMouse(new Vector2(_mouse.X, _mouse.Y - _size.Y + _padding.Y));
					}
					else if (_mouse.Y < 0 + _paddingSm.Y) {
						_regrab = true;
						GetViewport().WarpMouse(new Vector2(_mouse.X, _mouse.Y + _size.Y - _padding.Y));
					}

					if (_regrab)
						grab = GetGlobalMousePosition();
				}
			}

			if (Input.IsActionJustReleased("mmb")) {
				grabbed = false;
			}

			// Handle zoom
			if (Input.IsActionJustReleased("mwdn"))
				Zoom *= .9f;
			else if (Input.IsActionJustReleased("mwup"))
				Zoom *= 1.1f;
			
			if (Input.IsActionJustPressed("ui_home")) {
				unzooming = true;
				unzoomPosition = GetGlobalMousePosition();
			}
			if (unzooming)
				Unzoom(delta);
			ZoomClamp();
		}

		void ZoomClamp() {
			Zoom = new Vector2(Mathf.Clamp(Zoom.X, .1f, 50f), Mathf.Clamp(Zoom.Y, .1f, 50f));
		}

		void Unzoom(double delta) {
			if (Zoom.IsEqualApprox(new Vector2(1f, 1f))) {
				Zoom = new Vector2(1f, 1f);
				unzooming = false;
				return;
			}

			Zoom += (new Vector2(1f,1f) - Zoom) * (float)delta * 50f;
			Position += (unzoomPosition - Position) * (float)delta * 50f;
		}
	#endregion
}
