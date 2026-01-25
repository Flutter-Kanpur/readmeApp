import 'package:flutter/cupertino.dart';

class BlogEditorController {
  final TextEditingController contentController;

  BlogEditorController(this.contentController);

  void wrapSelection(String openTag, String closeTag) {
    final String text = contentController.text;
    final TextSelection selection = contentController.selection;
    if (!selection.isValid) return;
    final selectedText = selection.textInside(text);
    final replacement =
        openTag + (selectedText.isEmpty ? 'text' : selectedText) + closeTag;
    contentController.text = text.replaceRange(
      selection.start,
      selection.end,
      replacement,
    );
    contentController.selection = TextSelection.collapsed(
      offset: selection.start + replacement.length,
    );
  }

  void bold() => wrapSelection('<b>', '</b>');

  void italic() => wrapSelection('<i>', '</i>');

  void underline() => wrapSelection('<u>', '</u>');

  void strike() => wrapSelection('<s>', '</s>');

  // Headings & paragraph
  void heading1() => wrapSelection('<h1>', '</h1>');

  void heading2() => wrapSelection('<h2>', '</h2>');

  void paragraph() => wrapSelection('<p>', '</p>');

  // Lists & blocks
  void bulletList() => wrapSelection('<ul><li>', '</li></ul>');

  void quote() => wrapSelection('<blockquote>', '</blockquote>');

  void codeBlock() => wrapSelection('<pre><code>', '</code></pre>');

  // Links & media
  void insertLink(String url) {
    if (url.trim().isEmpty) return;
    wrapSelection('<a href="$url">', '</a>');
  }


  void insertImage(String imageUrl) {
    wrapSelection('<img src="$imageUrl" />', '');
  }
}
