import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class NumericInputController {
  final TextEditingController controller;
  int cursorPosition = 0;
  int maxLength;

  NumericInputController({
    TextEditingController? controller,
    this.maxLength = 15,
  }) : controller = controller ?? TextEditingController();

  void updateCursorPosition() {
    cursorPosition = controller.selection.baseOffset;
  }

  void handleKeyPress(String key) {
    final String formattedText = controller.text;
    final String currentText = formattedText.replaceAll('.', '');

    int unformattedCursor = 0;
    if (cursorPosition >= 0 && cursorPosition <= formattedText.length) {
      unformattedCursor =
          formattedText
              .substring(0, cursorPosition)
              .replaceAll('.', '')
              .length;
    } else {
      unformattedCursor = currentText.length;
    }

    if (key == '.000') {
      if (currentText.isEmpty) {
        _updateTextField('000', 3);
      } else {
        if (currentText.length + 3 > maxLength) return;
        final newText =
            currentText.substring(0, unformattedCursor) +
            '000' +
            currentText.substring(unformattedCursor);
        _updateTextField(newText, unformattedCursor + 3);
      }
    } else {
      if (currentText.length + 1 > maxLength) return;
      final newText =
          currentText.substring(0, unformattedCursor) +
          key +
          currentText.substring(unformattedCursor);
      _updateTextField(newText, unformattedCursor + 1);
    }
  }

  void handleBackspace() {
    final String formattedText = controller.text;
    final String currentText = formattedText.replaceAll('.', '');

    int unformattedCursor = 0;
    if (cursorPosition >= 0 && cursorPosition <= formattedText.length) {
      unformattedCursor =
          formattedText
              .substring(0, cursorPosition)
              .replaceAll('.', '')
              .length;
    } else {
      unformattedCursor = currentText.length;
    }

    if (unformattedCursor > 0) {
      final newText =
          currentText.substring(0, unformattedCursor - 1) +
          currentText.substring(unformattedCursor);
      _updateTextField(newText, unformattedCursor - 1);
    }
  }

  void _updateTextField(String newText, int newCursorPosition) {
    final formattedText = Formatters.formatNumberInput(newText);
    final textBeforeCursor = newText.substring(0, newCursorPosition);
    final formattedBeforeCursor = Formatters.formatNumberInput(
      textBeforeCursor,
    );
    final adjustedCursor = formattedBeforeCursor.length;

    controller.text = formattedText;
    controller.selection = TextSelection.collapsed(
      offset: adjustedCursor,
    );
    cursorPosition = adjustedCursor;
  }

  void clear() {
    controller.clear();
    cursorPosition = 0;
  }

  void dispose() {
    // Controller dipisahkan — screen bertanggung jawab dispose controller sendiri
  }
}
