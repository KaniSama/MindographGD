using Godot;
using System;

public partial class ProjectNameTextBox : LineEdit
{
	// Class variables
	string lastLine = "";
	int lastCaret = 0;

	// Signals
	public void OnTextChanged(string _newText) {
		if (StringExtensions.IsValidFileName(_newText) || String.IsNullOrEmpty(_newText)) {
			lastLine = _newText;
			lastCaret = CaretColumn;
		} else {
			Text = lastLine;
			CaretColumn = lastCaret;
		}
	}
}
