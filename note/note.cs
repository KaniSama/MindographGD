using Godot;
using System;

public partial class Note : Panel
{
	#region CustomSignals
		[Signal]
		public delegate void ClickedEventHandler();
		[Signal]
		public delegate void HoveredEventHandler(Note note);
		[Signal]
		public delegate void UnhoveredEventHandler(Note note);
		[Signal]
		public delegate void RemoveFromConnectionsEventHandler(Note note);
		[Signal]
		public delegate void SelectedClickEventHandler(Note note);
		[Signal]
		public delegate void SelectedRectEventHandler(Note note);
	#endregion


	#region ClassVariables
		int UID;

		Color color; // onready
		Panel noteBG; // onready -- $NoteContainer/NoteBg

		bool pinned = false;
		bool dragging = false;
		bool resizing = false;
		bool editing = false;

		//bool selected = false;

		Panel dragger; // onready -- $NoteContainer/Dragger
		Panel resizer; //onredy -- $NoteContainer/Resizer

		Vector2 pinPosition = new Vector2(0f,0f);
		TextureRect pinIcon; // onready -- $NoteContainer/PinIcon
		TextureRect pinShadow; // onready -- $NoteContainer/PinIcon2
		
		Vector2 offset;

		Button okButton; // onready -- $NoteContainer/OkButton
		Button cancelButton; // onready -- $NoteContainer/CancelButton

		TextEdit textEdit; // onready -- $NoteContainer/TextWrapper/TextEdit
		PanelContainer textWrapper; // onready -- $NoteContainer/TextWrapper
		Label noteText; // onready -- $NoteContainer/TextWrapper/NoteText

		Panel dropShadow; // onready -- $NoteContainer/DropShadow
		Panel darkModePanel; // onready -- $NoteContainer/DarkModePanel
	#endregion


	#region Overrides
		public override void _Ready()
		{
			// Set the values for Onready variables
			dragger = GetNode<Panel>("NoteContainer/Dragger");
			resizer = GetNode<Panel>("NoteContainer/Resizer");

			pinIcon = GetNode<TextureRect>("NoteContainer/PinIcon");
			pinShadow = GetNode<TextureRect>("NoteContainer/PinIcon2");

			okButton = GetNode<Button>("NoteContainer/OkButton");
			cancelButton = GetNode<Button>("NoteContainer/CancelButton");

			textWrapper = GetNode<PanelContainer>("NoteContainer/TextWrapper");
			textEdit = GetNode<TextEdit>("NoteContainer/TextWrapper/TextEdit");
			noteText = GetNode<Label>("NoteContainer/TextWrapper/NoteText");

			dropShadow = GetNode<Panel>("NoteContainer/DropShadow");
			darkModePanel = GetNode<Panel>("NoteContainer/DarkModePanel");

			// Exit text mode if it's open for some reason
			SetTextEditMode(false, false);
		}

		public override void _Process(double delta)
		{
			if (!pinned) {

				if (dragging) {
					Drag();
					dropShadow.Visible = true;
				} else {
					dropShadow.Visible = false;
				}

				if (resizing) {
					Resize();
				}

			} else {

				dropShadow.Visible = false;

			}
		}
	#endregion


	#region SizePosition
		private void OnDrag(bool _start = true) {
			if (_start) {
				offset = Position - GetGlobalMousePosition();
			}
			dragging = _start;
		}
		private void Drag() {
			Position = GetGlobalMousePosition() + offset;
			UpdatePinPosition();
		}


		private void OnResize(bool _start = true) {
			if (_start) {
				offset = GetGlobalMousePosition() - Size;
			}
			resizing = _start;
		}
		private void Resize() {
			Size = GetGlobalMousePosition() - offset;
			UpdatePinPosition();
		}


		private void Pin() {
			pinned = !pinned;
			dragger.Modulate = pinned ? new Color(0f,0f,0f,0f) : new Color(1f,1f,1f,.3882352f);

			pinIcon.Visible = pinned;
			pinShadow.Visible = pinned;
			resizer.Visible = !pinned;

			if (pinned)
				dragger.MouseDefaultCursorShape = CursorShape.PointingHand;
			else
				dragger.MouseDefaultCursorShape = CursorShape.Drag;
		}
		private void UpdatePinPosition() {
			pinPosition.X = Position.X + Size.X * .5f;
			pinPosition.Y = Position.Y + 8f;
		}
	#endregion


	#region Modes
		private void SetTextEditMode(bool _set = true, bool _saveText = false) {
			textEdit.Visible = _set;
			okButton.Visible = _set;
			cancelButton.Visible = _set;

			textEdit.SetProcess(_set);
			okButton.SetProcess(_set);
			cancelButton.SetProcess(_set);

			if (_set) {
				textEdit.GrabFocus();
				textEdit.SelectAll();
			} else {
				if (_saveText)
					noteText.Text = textEdit.Text;
			}
		}
	#endregion


	#region GetSetters
		private void SetColor(Color _newColor) {
			noteBG.Modulate = _newColor;
			color = _newColor;
		}


		private string GetText(bool _escaped = false) {
			if (_escaped) {
				return noteText.Text.CEscape();
			}

			return noteText.Text;
		}

		private void SetText(string _text) {
			noteText.Text = _text;
			textEdit.Text = _text;
		}

		
		private void SetUID(int _UID) {
			UID = _UID;
		}


		private void SetDarkMode(bool _set = true) {
			darkModePanel.Visible = _set;

			noteText.AddThemeColorOverride("font_color", _set ? color : new Color(0f,0f,0f,1f));
		}
	#endregion


	#region SignalEmitters
		private void EmitRemoveFromConnections() {
			EmitSignal(SignalName.RemoveFromConnections, this);
		}

		private void EmitClicked(InputEvent e = null) {
			EmitSignal(SignalName.Clicked, e);
		}

		private void EmitHovered(Note _note = null) {
			EmitSignal(SignalName.Hovered, _note);
		}

		private void EmitUnhovered(Note _note = null) {
			EmitSignal(SignalName.Unhovered, _note);
		}
	#endregion

	#region SignalConnections
		private void OnDraggerGuiInput(InputEvent @event) {
			if (@event is InputEventMouseButton) {
				EmitClicked(@event);

				if (@event.IsActionPressed("lmb"))
					OnDrag();
				else if (@event.IsActionReleased("lmb"))
					OnDrag(false);
				
				InputEventMouseButton e = (InputEventMouseButton)@event; // Explicit cast because only InputEventMouseButton has DoubleClick prop
				if (e.DoubleClick)
					Pin();
			}
		}
		
		private void OnResizerGuiInput(InputEvent @event) {
			if (@event is InputEventMouseButton) {
				EmitClicked(@event);

				if (@event.IsActionPressed("lmb"))
					OnResize();
				else if (@event.IsActionReleased("lmb"))
					OnResize(false);
			}
		}

		private void OnTextWrapperGuiInput(InputEvent @event) {
			if (@event is InputEventMouseButton) {
				EmitClicked(@event);

				InputEventMouseButton e = (InputEventMouseButton)@event; // Explicit cast because only InputEventMouseButton has DoubleClick prop
				if (e.DoubleClick)
					SetTextEditMode(true);
			}
		}

		private void OnOKButtonPressed() {
			SetTextEditMode(false, true);
			EmitClicked();
		}

		private void OnCancelButtonPressed() {
			SetTextEditMode(false, false);
			EmitClicked();
		}

		private void OnTextEditGuiInput(InputEvent @event) {
			if (@event.IsActionPressed("lmb") || @event.IsActionReleased("lmb"))
				EmitClicked(@event);
		}

		private void OnNoteBGGuiInput(InputEvent @event) {
			if (@event is InputEventMouseButton)
				EmitClicked(@event);
		}


		// private void OnMouseEntered() {
		// 	EmitHovered(this);
		// }
		// private void OnMouseExited() {
		// 	EmitUnhovered(this);
		// }


		private void OnGuiInput(InputEvent @event) {
			if (@event is InputEventMouseButton)
				EmitClicked(@event);
		}
	#endregion
}


