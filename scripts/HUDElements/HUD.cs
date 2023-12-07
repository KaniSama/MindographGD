using Godot;
using System;
using System.Collections.Generic;

using Workspace;

public partial class HUD : Control
{
	#region CustomSignals
		[Signal]
		public delegate void HudButtonAddPressedEventHandler();
		[Signal]
		public delegate void HudButtonSavePressedEventHandler();
		[Signal]
		public delegate void NewNoteEventHandler(Note _note);
		[Signal]
		public delegate void CreateLinkEventHandler(Note _note1);
		[Signal]
		public delegate void OpenProjectRequestedEventHandler();
		[Signal]
		public delegate void CreateProjectRequestedEventHandler();
		[Signal]
		public delegate void OpenSettingsRequestedEventHandler();
		[Signal]
		public delegate void OpenReplaceRequestedEventHandler();
	#endregion


	#region ClassVariables
	// RMB menus
		CanvasLayer canvas; // onready -- $CanvasLayer
		ItemList rmbMenu; // onready -- $CanvasLayer/MenuBackdrop/RMBMenu
		Panel menuBackdrop; // onready -- $CanvasLayer/MenuBackdrop
		Control linkDrawer; // onready -- $LinkDrawer
		Control linkDrawerStart; // onready -- $LinkDrawerStart
		Panel colorPicker; // onready -- $CanvasLayer/MenuBackdrop/ColorPickerBackdrop

	// Modal dialogs
		Panel dialogBackdrop; // onready -- $CanvasLayer/DialogBackdrop
		VBoxContainer dialog; // onready -- $CanvasLayer/DialogBackdrop/DialogList

		Panel projectListBackground; // onready -- $CanvasLayer/DialogBackdrop/ProjectListBackground
		ItemList projectList; // onready -- $CanvasLayer/DialogBackdrop/ProjectListBackground/ProjectListContainer
		LineEdit projectNameTextBox; // onready -- $CanvasLayer/DialogBackdrop/DialogList/ProjectNameTextBox

	// Buttons
		Panel buttonContainer; // onready -- $CanvasLayer/ButtonContainer

	// Color
		bool coloring = false;
		Workspace parent; // onready -- $..
		Color currentColor; // onready -- parent.GetLastColor();

	// Selector
		Control selector; // onready -- $Selector
		public enum selectionModes {
			OFF = 0,
			SELECT = 1,
			ADD = 2,
			SUBTRACT = 3
		}

		selectionModes selectionMode = selectionModes.OFF;
		bool selecting = false;
		Vector2 selectionBegin = new Vector2(0,0);
		Vector2 selectionEnd = new Vector2(0,0);

	// Vars
		Note target = null;
		Note linkTarget = null;
		bool drawingLink = false;
	#endregion


	#region Overrides
		public override void _Ready()
		{
			// Set onready variables
			canvas = GetNode<CanvasLayer>("CanvasLayer");
			rmbMenu = GetNode<ItemList>("CanvasLayer/MenuBackdrop/RMBMenu");
			menuBackdrop = GetNode<Panel>("CanvasLayer/MenuBackdrop");
			linkDrawer = GetNode<Control>("LinkDrawer");
			linkDrawerStart = GetNode<Control>("LinkDrawerStart");
			colorPicker = GetNode<Panel>("CanvasLayer/MenuBackdrop/ColorPickerBackdrop");

			dialogBackdrop = GetNode<Panel>("CanvasLayer/DialogBackdrop");
			dialog = GetNode<VBoxContainer>("CanvasLayer/DialogBackdrop/DialogList");

			projectListBackground = GetNode<Panel>("CanvasLayer/DialogBackdrop/ProjectListBackground");
			projectList = GetNode<ItemList>("CanvasLayer/DialogBackdrop/ProjectListBackground/ProjectListContainer");
			projectNameTextBox = GetNode<LineEdit>("CanvasLayer/DialogBackdrop/DialogList/ProjectNameTextBox");

			buttonContainer = GetNode<Panel>("CanvasLayer/ButtonContainer");

			parent = GetNode<Workspace>("..");
			currentColor = parent.GetLastColor();

			selector = GetNode<Control>("Selector");


			// Set up the project list
			RefreshProjectList();
		}

		public override void _Process(double delta)
		{
			linkDrawer.Visible = drawingLink;
			colorPicker.Visible = coloring;

			if (coloring && target is not null)
				target.SetColor(currentColor);
		}

		public override void _Input(InputEvent @event) {

			if (drawingLink)
				if (@event.IsActionPressed("lmb")) {
					FinishLink();
				} else if (@event.IsActionPressed("rmb")) {
					drawingLink = false;
					QueueRedraw();
				}
			
			bool __changed = false;
			if (@event.IsActionPressed("selection")) {
				if (selectionMode == selectionModes.OFF) {
					SetSelectionMode(selectionModes.SELECT);
					__changed = true;
				}
			} else if (Input.IsActionJustReleased("selection")) {
				SetSelectionMode(selectionModes.OFF);
				__changed = true;
			}
			// if (__changed) GD.Print("Selection mode " + (selectionMode != selectionModes.OFF ? "on" : "off"));

			if (selectionMode != selectionModes.OFF) {
				if (@event.IsActionPressed("lmb"))
					SetSelecting();
				else if (Input.IsActionJustReleased("lmb"))
					SetSelecting(false);
				
				if (selecting) {
					selector.Position = GetGlobalMousePosition();
					QueueRedraw();

					selectionEnd = selector.Position;
				}
			}
		}

		public override void _Draw() {
			if (selectionMode != selectionModes.OFF && selecting) {
				DrawRect(new Rect2(selectionBegin, selectionEnd - selectionBegin), new Color(1,1,1,1), false);
				DrawRect(new Rect2(selectionBegin, selectionEnd - selectionBegin), new Color(1,1,1,.25f), true);
			}
		}
	#endregion


	#region GetSetters
		public bool IsPopupVisible() {
			return dialogBackdrop.Visible || menuBackdrop.Visible;
		}

		public void SetSelectionMode(selectionModes _mode = selectionModes.SELECT) {
			selectionMode = _mode;

			if (_mode == selectionModes.OFF)
				SetSelecting(false);
		}

		public void SetSelecting(bool _set = true) {
			selecting = _set;

			selectionBegin = GetGlobalMousePosition();

			QueueRedraw();
		}
	#endregion


	#region TargetingFunctions
		public void SetTarget(Note _newTarget = null) {
			target = _newTarget;
		}
		public void SetLinkTarget(Note _newTarget = null) {
			linkTarget = _newTarget;
		}
	#endregion


	#region ModalWindows
		public void ShowButtonContainer(bool _show = true) {
			buttonContainer.Visible = _show;
		}

		public void ShowDialogBackdrop(bool _show = true) {
			ShowButtonContainer(!_show);
			dialogBackdrop.Visible = _show;
		}
		public void ShowProjectNameChangeDialogWindow(bool _show = true) {
			ShowDialogBackdrop(_show);
			dialog.Visible = _show;
		}
		public void ShowProjectList(bool _show = true) {
			ShowDialogBackdrop(_show);
			projectListBackground.Visible = _show;

			RefreshProjectList();
		}

		public void RefreshProjectList() {
			SetProjectList(parent.GetProjectList());
		}
		public void SetProjectList(List<string> _projects) {
			projectList.Clear();
			projectList.AddItem("+ New Project!", ResourceLoader.Load("res://sprites/sPin.png") as Texture, true);
			projectList.AddItem("", null, false);

			foreach (string __project in _projects)
				projectList.AddItem(__project, null, true);
		}
	#endregion


	#region RMBMenu
		public void OpenRMBMenu(bool _open = true) {
			rmbMenu.Visible = _open;
			menuBackdrop.Visible = _open;

			if (_open) {
				Vector2 __mpos = GetViewport().GetMousePosition();
				rmbMenu.Position = new Vector2(
					Mathf.Clamp(__mpos.X, 0, GetViewportRect().Size.X - rmbMenu.Size.X),
					Mathf.Clamp(__mpos.Y, 0, GetViewportRect().Size.Y - rmbMenu.Size.Y)
				);
			} else {
				coloring = false;
			}
		}
	#endregion


	#region Linking
		public void SetLinkStatus(bool _start) {
			if (_start)
				EmitSignal(SignalName.CreateLink, linkTarget);
			
			drawingLink = true;

			QueueRedraw();
		}
	#endregion


	#region HelperFunctions
		public bool PointWithin(Vector2 _point, Vector2 _posStart, Vector2 _posEnd) {
			return (
				_point.X >= _posStart.X
				&& _point.X <= _posEnd.X
				&& _point.Y >= _posStart.Y
				&& _point.Y <= _posEnd.Y
			);
		}

		public bool NoteWithin(Note _note, Vector2 _posStart, Vector2 _posEnd) {
			Vector2[] _noteCorners = {
				_note.Position,
				new Vector2(_note.Position.X + _note.Size.X, _note.Position.Y),
				new Vector2(_note.Position.X, _note.Position.Y + _note.Size.Y),
				_note.Position + _note.Size
			};

			foreach (Vector2 __i in _noteCorners) {
				if (PointWithin(__i, _posStart, _posEnd))
					return true;
			}

			return false;
		}
	#endregion


	#region Signals
		private void OnButtonAddPressed()
		{
			EmitSignal(SignalName.HudButtonAddPressed);
		}
		private void OnButtonSavePressed()
		{
			EmitSignal(SignalName.HudButtonSavePressed);
		}
		private void OnButtonLoadPressed()
		{
			ShowProjectList();
		}
		private void OnButtonReplacePressed()
		{
			EmitSignal(SignalName.OpenReplaceRequested);
		}
		private void OnButtonSettingsPressed()
		{
			EmitSignal(SignalName.OpenSettingsRequested);
		}


		private void OnMenuBackdropGuiInput(InputEvent @event)
		{
			if (@event.IsActionPressed("lmb"))
				OpenRMBMenu(false);
		}


		private void OnRMBMenuItemClicked(long _index, Vector2 _atPosition, long _mouseButtonIndex)
		{
			if (_mouseButtonIndex == MouseButton.Left) {
				bool __closeMenu = true;

				rmbMenu.DeselectAll();

				switch (_index) {
					case rmbMenu.RmbIDs.PIN:
						target.Pin();
						break;
					
					case rmbMenu.RmbIDs.LINK:
						SetLinkTarget(target);
						SetLinkStatus(true);
						break;
					
					case rmbMenu.RmbIDs.NEW:
						EmitSignal(SignalName.NewNote, target);
						break;
					
					case rmbMenu.RmbIDs.DELETE:
						target.QueueFree();
						break;
					
					case rmbMenu.RmbIDs.UNLINK:
						target.RemoveFromConnections();
						break;

					case rmbMenu.RmbIDs.COLOR:
						__closeMenu = false;

						Vector2 __mousePos = rmbMenu.Position + _atPosition;

						currentColor = target.color;
						colorPicker.FindChild("ColorPicker", false).Color = target.color;
						colorPicker.Position = new Vector2(
							Mathf.Clamp(__mousePos.X, 0, GetViewportRect().End.X - colorPicker.Size.X),
							Mathf.Clamp(__mousePos.Y, 0, GetViewportRect().End.Y - colorPicker.Size.Y)
						);
						coloring = true;
				}

				if (__closeMenu)
					OpenRMBMenu(false);
			}
		}

		private void OnColorPickerColorChanged(Color _color)
		{
			currentColor = _color;
			parent.SetLastColor(_color);
		}


		private void OnDialogButtonOKPressed()
		{
			/// TODO : CHANGE THE REPLACE TO REPLACECASEINSENSITIVE !!!
			string _text = projectNameTextBox.Text.Trim().Replace(".mg", "");
		}
		private void OnDialogButtonCancelPressed()
		{
			ShowProjectNameChangeDialogWindow(false);
			ShowProjectList();
		}


		private void OnProjectListContainerItemActivated(long _index)
		{
			if (_index == 0) {
				ShowProjectList(false);
				ShowProjectNameChangeDialogWindow();
				return;
			}

			string _projectName = projectList.GetItemText(_index);
			EmitSignal(SignalName.OpenProjectRequested, _projectName);
			ShowProjectList(false);
		}
		private void OnProjectListContainerItemClicked(long _index, Vector2 _atPosition, long _mouseButtonIndex)
		{
			if (_index == 0) {
				ShowProjectList(false);
				ShowProjectNameChangeDialogWindow();
				return;
			}
		}
		private void OnProjectListButtonCancelPressed()
		{
			ShowProjectList(false);
		}
		private void OnProjectListButtonOpenDirPressed()
		{
			SetProjectList(parent.GetProjectList());
			OS.ShellOpen(ProjectSettings.GlobalizePath("user://Projects"));
		}
	#endregion
}



