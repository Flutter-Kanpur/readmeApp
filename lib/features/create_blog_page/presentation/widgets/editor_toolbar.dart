import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';

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
      // elevation: 10,
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
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: _insertLocalImage,
            ),
          ],
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

  /// ✅ Insert image locally (NO upload here)
  void _insertLocalImage() async {
    final picker = ImagePicker();
    final XFile? picked =
    await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    focusNode.requestFocus();

    final index = controller.selection.baseOffset >= 0
        ? controller.selection.baseOffset
        : controller.document.length;

    controller.replaceText(
      index,
      0,
      quill.BlockEmbed.image(picked.path),
      TextSelection.collapsed(offset: index + 1),
    );
    controller.replaceText(
      index + 1,
      0,
      '\n',
      TextSelection.collapsed(offset: index + 2),
    );
  }
}
