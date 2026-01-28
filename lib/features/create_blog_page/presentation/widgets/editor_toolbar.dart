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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toggleFormat(Icons.format_bold, quill.Attribute.bold),
            _toggleFormat(Icons.format_italic, quill.Attribute.italic),
            _toggleFormat(Icons.format_underlined, quill.Attribute.underline),
            _toggleFormat(Icons.format_list_bulleted, quill.Attribute.ul),
            _toggleFormat(Icons.format_list_numbered, quill.Attribute.ol),
            _toggleFormat(Icons.code, quill.Attribute.codeBlock),
            _toggleFormat(Icons.format_quote, quill.Attribute.blockQuote),
            IconButton(
              icon: const Icon(Icons.link),
              onPressed: () => _handleLink(context),
            ),

            IconButton(
              icon: const Icon(Icons.image),
              onPressed: _insertLocalImage,
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ MINIMAL toggle logic (nothing extra)
  Widget _toggleFormat(IconData icon, quill.Attribute attribute) {
    return IconButton(
      icon: Icon(icon),
      onPressed: () {
        final attrs = controller.getSelectionStyle().attributes;

        if (attrs.containsKey(attribute.key)) {
          controller.formatSelection(quill.Attribute.clone(attribute, null));
        } else {
          controller.formatSelection(attribute);
        }

        focusNode.requestFocus();
      },
    );
  }

  /// ✅ Image logic unchanged
  void _insertLocalImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

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

  void _handleLink(BuildContext context) async {
    final selection = controller.selection;

    // No text selected → do nothing
    if (selection.isCollapsed) return;

    final attrs = controller.getSelectionStyle().attributes;

    // If link already exists → remove it
    if (attrs.containsKey(quill.Attribute.link.key)) {
      controller.formatSelection(
        quill.Attribute.clone(quill.Attribute.link, null),
      );
      focusNode.requestFocus();
      return;
    }

    final urlController = TextEditingController();

    final url = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add link'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(hintText: 'https://example.com'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final value = urlController.text.trim();
                Navigator.pop(context, value.isEmpty ? null : value);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (url == null) return;

    controller.formatSelection(
      quill.Attribute.clone(quill.Attribute.link, url),
    );

    focusNode.requestFocus();
  }
}
