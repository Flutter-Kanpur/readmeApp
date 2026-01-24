import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class EditorToolbar extends StatelessWidget {
  final quill.QuillController controller;
  final FocusNode focusNode;

  const EditorToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      child: SizedBox(
        height: 56,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _formatBtn(Icons.format_bold, quill.Attribute.bold),
              _formatBtn(Icons.format_italic, quill.Attribute.italic),
              _formatBtn(Icons.format_underlined, quill.Attribute.underline),
              _formatBtn(Icons.format_list_bulleted, quill.Attribute.ul),
              _formatBtn(Icons.format_list_numbered, quill.Attribute.ol),
              _formatBtn(Icons.format_quote, quill.Attribute.blockQuote),
              _formatBtn(Icons.code, quill.Attribute.codeBlock),

              // ✅ IMAGE BUTTON (SAFE)
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: _insertImage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formatBtn(IconData icon, quill.Attribute attribute) {
    return IconButton(
      icon: Icon(icon),
      onPressed: () => controller.formatSelection(attribute),
    );
  }

  // --------------------------------------------------
  // ✅ SAFE IMAGE INSERT (NO ASYNC, NO POST-FRAME)
  // --------------------------------------------------
  void _insertImage() {
    const imageUrl = 'https://picsum.photos/600/300';

    // Keep editor focused
    focusNode.requestFocus();

    final selection = controller.selection;

    final index = (selection.isValid && selection.baseOffset >= 0)
        ? selection.baseOffset
        : controller.document.length;

    controller.replaceText(
      index,
      0,
      quill.BlockEmbed.image(imageUrl),
      TextSelection.collapsed(offset: index + 1),
    );
  }
}
