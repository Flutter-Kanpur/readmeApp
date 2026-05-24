import 'dart:convert';

import 'package:Readme/core/utils/app_image.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:markdown/markdown.dart' as md;
enum BlogContentFormat { quillDelta, html, markdown, plainText }

final _htmlUnescape = HtmlUnescape();

/// Keeps the original formatted content from Supabase (Quill JSON or HTML).
String normalizeRawContent(dynamic content) {
  if (content == null) return '';
  if (content is String) return content;

  if (content is Map) {
    for (final key in ['contentHtml', 'html', 'content_html', 'body']) {
      final value = content[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    for (final key in [
      'contentMarkdown',
      'markdown',
      'content_markdown',
      'body_markdown',
    ]) {
      final value = content[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    if (content['ops'] is List) return jsonEncode({'ops': content['ops']});
    return jsonEncode(content);
  }

  if (content is List) return jsonEncode(content);
  return content.toString();
}

/// Unwrap JSON-encoded strings and decode HTML entities when needed.
String normalizeForRendering(String content) {
  var text = content.trim();
  if (text.isEmpty) return text;

  if (text.startsWith('"') && text.endsWith('"')) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is String) text = decoded.trim();
    } catch (_) {}
  }

  if (text.contains('&lt;') ||
      text.contains('&gt;') ||
      text.contains('&amp;') ||
      text.contains('&#')) {
    text = _htmlUnescape.convert(text);
  }

  return text;
}

BlogContentFormat detectBlogContentFormat(String content) {
  final trimmed = normalizeForRendering(content);
  if (trimmed.isEmpty) return BlogContentFormat.plainText;

  if (extractQuillOps(trimmed) != null) {
    return BlogContentFormat.quillDelta;
  }

  if (_looksLikeHtml(trimmed)) {
    return BlogContentFormat.html;
  }

  if (_looksLikeMarkdown(trimmed)) {
    return BlogContentFormat.markdown;
  }

  return BlogContentFormat.plainText;
}

bool _looksLikeHtml(String content) {
  return content.contains('<') &&
      RegExp(
        r'<\s*(p|div|br|strong|b|em|i|ul|ol|li|h[1-6]|blockquote|figure|span|img|a)\b',
        caseSensitive: false,
      ).hasMatch(content);
}

bool _looksLikeMarkdown(String content) {
  return RegExp(
    r'(^|\n)(#{1,6}\s|(\*\*|__)(?=\S)|\*(?=\S)|-\s+\S|\d+\.\s+\S)',
    multiLine: true,
  ).hasMatch(content);
}

List<dynamic>? extractQuillOps(String content) {
  final trimmed = content.trim();
  if (trimmed.isEmpty) return null;

  try {
    if (trimmed.startsWith('[')) {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) return decoded;
    }

    if (trimmed.startsWith('{')) {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        if (decoded['ops'] is List) return decoded['ops'] as List;
        if (decoded['delta'] is List) return decoded['delta'] as List;
      }
    }
  } catch (_) {}

  return null;
}

/// Converts stored blog content into a Quill [Delta] for rich rendering.
Delta contentToDelta(
  String content, {
  List<String>? imageUrls,
  String? Function(String storagePath)? storagePathToUrl,
}) {
  final normalized = normalizeForRendering(content);

  final ops = extractQuillOps(normalized);
  if (ops != null) {
    return Delta.fromJson(
      prepareQuillOpsFromList(
        ops,
        imageUrls: imageUrls,
        storagePathToUrl: storagePathToUrl,
      ),
    );
  }

  if (_looksLikeHtml(normalized)) {
    return _htmlToDelta(
      normalized,
      imageUrls: imageUrls,
      storagePathToUrl: storagePathToUrl,
    );
  }

  if (_looksLikeMarkdown(normalized)) {
    final html = md.markdownToHtml(
      normalized,
      extensionSet: md.ExtensionSet.gitHubWeb,
    );
    return _htmlToDelta(
      html,
      imageUrls: imageUrls,
      storagePathToUrl: storagePathToUrl,
    );
  }

  return _plainTextToDelta(normalized);
}

Delta _htmlToDelta(
  String html, {
  List<String>? imageUrls,
  String? Function(String storagePath)? storagePathToUrl,
}) {
  try {
    final rewritten = rewriteHtmlImageSources(
      html,
      imageUrls: imageUrls,
      storagePathToUrl: storagePathToUrl,
    );
    return HtmlToDelta(
      replaceNormalNewLinesToBr:
          !rewritten.contains('<p') && !rewritten.contains('<div'),
    ).convert(rewritten);
  } catch (_) {
    return _plainTextToDelta(parseQuillContent(html));
  }
}

/// Medium HTML bold/italic uses styled spans, not semantic tags. Convert before
/// stripping inline styles so emphasis survives on mobile.
String convertInlineEmphasisToSemanticHtml(String html) {
  var result = html;
  final boldPattern = RegExp(
    r'font-weight\s*:\s*(?:bold|bolder|[6-9]00)\b',
    caseSensitive: false,
  );
  final italicPattern = RegExp(
    r'font-style\s*:\s*italic\b',
    caseSensitive: false,
  );

  String wrapEmphasis(String style, String inner) {
    var output = inner;
    if (boldPattern.hasMatch(style)) {
      output = '<strong>$output</strong>';
    }
    if (italicPattern.hasMatch(style)) {
      output = '<em>$output</em>';
    }
    return output;
  }

  for (var pass = 0; pass < 4; pass++) {
    final before = result;

    result = result.replaceAllMapped(
      RegExp(
        r'<span\b[^>]*\sstyle="([^"]*)"[^>]*>([\s\S]*?)</span>',
        caseSensitive: false,
      ),
      (match) {
        final style = match.group(1)!;
        final inner = match.group(2)!;
        final wrapped = wrapEmphasis(style, inner);
        return wrapped == inner ? match.group(0)! : wrapped;
      },
    );

    result = result.replaceAllMapped(
      RegExp(
        r"<span\b[^>]*\sstyle='([^']*)'[^>]*>([\s\S]*?)</span>",
        caseSensitive: false,
      ),
      (match) {
        final style = match.group(1)!;
        final inner = match.group(2)!;
        final wrapped = wrapEmphasis(style, inner);
        return wrapped == inner ? match.group(0)! : wrapped;
      },
    );

    if (result == before) break;
  }

  return result;
}

/// Flattens Medium `<pre><span>code</span></pre>` into plain `<pre>code</pre>`.
String normalizePreBlocks(String html) {
  return html.replaceAllMapped(
    RegExp(r'<pre\b[^>]*>([\s\S]*?)</pre>', caseSensitive: false),
    (match) {
      var inner = match.group(1)!;
      inner = inner.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
      inner = inner.replaceAll(RegExp(r'<[^>]+>'), '');
      inner = _htmlUnescape.convert(inner);
      return '<pre>${inner.trim()}</pre>';
    },
  );
}

String sanitizeHtmlForMobile(
  String html, {
  String? excludeImageUrl,
}) {
  var result = html;

  result = result.replaceAll(
    RegExp(
      r'<figcaption[^>]*>[\s\S]*?Press enter or click[\s\S]*?</figcaption>',
      caseSensitive: false,
    ),
    '',
  );

  result = result.replaceAll(
    RegExp(
      r'Press enter or click to view image in full size',
      caseSensitive: false,
    ),
    '',
  );

  result = convertInlineEmphasisToSemanticHtml(result);

  result = normalizePreBlocks(result);

  result = result.replaceAllMapped(
    RegExp(r'width\s*:\s*\d+(?:\.\d+)?px', caseSensitive: false),
    (_) => 'max-width: 100%',
  );
  result = result.replaceAllMapped(
    RegExp(r'min-width\s*:\s*\d+(?:\.\d+)?px;?', caseSensitive: false),
    (_) => '',
  );
  result = result.replaceAllMapped(
    RegExp(r'max-width\s*:\s*\d+(?:\.\d+)?px', caseSensitive: false),
    (_) => 'max-width: 100%',
  );
  result = result.replaceAllMapped(
    RegExp(r'white-space\s*:\s*nowrap', caseSensitive: false),
    (_) => 'white-space: normal',
  );
  result = result.replaceAllMapped(
    RegExp(r'overflow\s*:\s*hidden', caseSensitive: false),
    (_) => '',
  );
  result = result.replaceAllMapped(
    RegExp(r'text-overflow\s*:\s*ellipsis', caseSensitive: false),
    (_) => '',
  );

  result = result.replaceAll(
    RegExp(r'\sstyle="[^"]*"', caseSensitive: false),
    '',
  );
  result = result.replaceAll(
    RegExp(r"\sstyle='[^']*'", caseSensitive: false),
    '',
  );
  result = result.replaceAll(
    RegExp(r'\swidth="[^"]*"', caseSensitive: false),
    '',
  );
  result = result.replaceAll(
    RegExp(r'\sheight="[^"]*"', caseSensitive: false),
    '',
  );

  return result;
}

/// Parses Medium-style HTML into renderable blocks (paragraphs, headings, images).
List<String> prepareHtmlContentBlocks(
  String html, {
  List<String>? imageUrls,
  String? Function(String storagePath)? storagePathToUrl,
  String? excludeImageUrl,
}) {
  final sanitized = sanitizeHtmlForMobile(
    rewriteHtmlImageSources(
      html,
      imageUrls: imageUrls,
      storagePathToUrl: storagePathToUrl,
    ),
  );
  return flattenMediumHtml(
    sanitized,
    excludeImageUrl: excludeImageUrl,
  );
}

String? extractFirstImageUrl(
  String html, {
  String? Function(String storagePath)? storagePathToUrl,
}) {
  final resolved = rewriteHtmlImageSources(
    html,
    storagePathToUrl: storagePathToUrl,
  );
  for (final attr in ['src', 'data-src', 'data-original']) {
    final match = RegExp(
      '<img\\b[^>]*\\b$attr=(["\'])([^"\']+)\\1',
      caseSensitive: false,
    ).firstMatch(resolved);
    if (match != null) {
      final url = match.group(2)!.trim();
      if (url.isNotEmpty) return url;
    }
  }
  return null;
}

bool _sameImageUrl(String a, String b) {
  String norm(String value) => value.trim().replaceAll(RegExp(r'/+$'), '');
  return norm(a) == norm(b);
}

String? _imageUrlFromHtmlBlock(String block) {
  for (final attr in ['src', 'data-src', 'data-original']) {
    final match = RegExp(
      '$attr=(["\'])([^"\']+)\\1',
      caseSensitive: false,
    ).firstMatch(block);
    if (match != null) {
      final url = match.group(2)!.trim();
      if (url.isNotEmpty) return url;
    }
  }
  return null;
}

String? _figureToImgTag(String figureHtml) {
  final url = _imageUrlFromHtmlBlock(figureHtml);
  if (url == null) return null;
  return '<img src="$url" />';
}

/// Pulls readable block elements out of Medium's nested flex/680px wrappers so
/// flutter_html lays out at full screen width instead of shrink-wrapping.
List<String> flattenMediumHtml(
  String html, {
  String? excludeImageUrl,
}) {
  final pattern = RegExp(
    r'<(?:p|h[1-6]|figure|ul|ol|blockquote|pre)\b[^>]*>[\s\S]*?</(?:p|h[1-6]|figure|ul|ol|blockquote|pre)>',
    caseSensitive: false,
  );
  final blocks = <String>[];

  for (final match in pattern.allMatches(html)) {
    var block = match.group(0)!;
    if (RegExp(r'^<figure\b', caseSensitive: false).hasMatch(block)) {
      block = _figureToImgTag(block) ?? block;
    }

    if (RegExp(r'^<img\b', caseSensitive: false).hasMatch(block.trim())) {
      final url = _imageUrlFromHtmlBlock(block);
      if (url == null) continue;
      if (excludeImageUrl != null && _sameImageUrl(url, excludeImageUrl)) {
        continue;
      }
      blocks.add(block.trim());
      continue;
    }

    if (block.trim().isNotEmpty) {
      blocks.add(block);
    }
  }

  if (blocks.isEmpty) return [html];
  return blocks;
}

String rewriteHtmlImageSources(
  String html, {
  List<String>? imageUrls,
  String? Function(String storagePath)? storagePathToUrl,
}) {
  var result = html;

  for (final attr in ['src', 'data-src', 'data-original']) {
    result = result.replaceAllMapped(
      RegExp('$attr=(["\'])([^"\']+)\\1', caseSensitive: false),
      (match) {
        final quote = match.group(1)!;
        final rawSrc = match.group(2)!;
        final resolved = resolveInlineImageSource(
          rawSrc,
          imageUrls: imageUrls,
          storagePathToUrl: storagePathToUrl,
        );
        if (resolved.isEmpty) return '';
        return '$attr=$quote$resolved$quote';
      },
    );
  }

  return result;
}

Delta _plainTextToDelta(String text) {
  final delta = Delta();
  final lines = text.split('\n');

  for (final line in lines) {
    final trimmed = line.trim();

    if (trimmed.isEmpty) {
      delta.insert('\n');
      continue;
    }

    final bullet = RegExp(r'^([•\-*]|\d+\.)\s+(.*)$').firstMatch(trimmed);
    if (bullet != null) {
      final listType = bullet.group(1)!.contains('.') ? 'ordered' : 'bullet';
      delta.insert('${bullet.group(2)}\n', {'list': listType});
      continue;
    }

    delta.insert('$trimmed\n');
  }

  if (delta.isEmpty) {
    delta.insert('\n');
  }

  return delta;
}

/// Parses blog content (Quill Delta JSON or HTML) and returns plain text for previews.
String parseQuillContent(dynamic content) {
  final raw = normalizeRawContent(content);
  if (raw.isEmpty) return '';

  final normalized = normalizeForRendering(raw);
  final format = detectBlogContentFormat(normalized);

  if (format == BlogContentFormat.quillDelta) {
    try {
      return _extractTextFromDelta(extractQuillOps(normalized));
    } catch (_) {
      return normalized;
    }
  }

  if (format == BlogContentFormat.html) {
    return _stripHtmlToPlainText(normalized);
  }

  if (format == BlogContentFormat.markdown) {
    return _stripHtmlToPlainText(
      md.markdownToHtml(normalized, extensionSet: md.ExtensionSet.gitHubWeb),
    );
  }

  return normalized;
}

/// Replaces [[IMAGE0]] placeholders with image embed ops for Quill rendering.
List<dynamic> prepareQuillOpsFromList(
  List<dynamic> ops, {
  List<String>? imageUrls,
  String? Function(String storagePath)? storagePathToUrl,
}) {
  final placeholderRegex = RegExp(r'\[\[IMAGE_?(\d+)\]\]');
  final prepared = <dynamic>[];

  void addImageEmbed(String source) {
    final resolved = resolveInlineImageSource(
      source,
      imageUrls: imageUrls,
      storagePathToUrl: storagePathToUrl,
    );
    if (resolved.isEmpty) return;
    prepared.add({'insert': {'image': resolved}});
    prepared.add({'insert': '\n'});
  }

  for (final op in ops) {
    if (op is! Map) continue;

    final insert = op['insert'];

    if (insert is Map && insert['image'] is String) {
      addImageEmbed(insert['image'] as String);
      continue;
    }

    if (insert is! String) {
      prepared.add(op);
      continue;
    }

    if (!insert.contains('[[')) {
      prepared.add(op);
      continue;
    }

    var cursor = 0;
    var matchedPlaceholder = false;

    for (final match in placeholderRegex.allMatches(insert)) {
      matchedPlaceholder = true;
      if (match.start > cursor) {
        prepared.add(_copyOpWithInsert(op, insert.substring(cursor, match.start)));
      }

      final index = int.tryParse(match.group(1)!);
      if (imageUrls != null &&
          index != null &&
          index >= 0 &&
          index < imageUrls.length) {
        addImageEmbed(imageUrls[index]);
      }

      cursor = match.end;
    }

    if (!matchedPlaceholder) {
      prepared.add(op);
      continue;
    }

    if (cursor < insert.length) {
      prepared.add(_copyOpWithInsert(op, insert.substring(cursor)));
    }
  }

  return prepared;
}

@Deprecated('Use prepareQuillOpsFromList instead')
List<dynamic> prepareQuillOpsForDisplay(
  String content, {
  List<String>? imageUrls,
}) {
  final ops = extractQuillOps(content);
  if (ops == null) return [];
  return prepareQuillOpsFromList(
    ops,
    imageUrls: imageUrls,
  );
}

Map<String, dynamic> _copyOpWithInsert(Map op, String insert) {
  return {
    ...op.map((key, value) => MapEntry(key.toString(), value)),
    'insert': insert,
  };
}

/// Strip HTML tags and base64 image data to plain text for card previews.
String _stripHtmlToPlainText(String html) {
  String text = html;
  text = text.replaceAll(
    RegExp(r'data:image/[^;]+;base64,[A-Za-z0-9+/=]+', caseSensitive: false),
    '',
  );
  text = text.replaceAll(RegExp(r'<img[^>]*>', caseSensitive: true), ' ');
  text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ');
  text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), ' ');
  text = text.replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), ' ');
  text = text.replaceAll(RegExp(r'</li>', caseSensitive: false), ' ');
  text = text.replaceAll(RegExp(r'</pre>', caseSensitive: false), ' ');
  text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
  text = text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"');
  return _collapsePreviewWhitespace(text);
}

String _collapsePreviewWhitespace(String text) {
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Extracts plain text from Quill Delta format
String _extractTextFromDelta(dynamic deltaData) {
  if (deltaData == null) return '';

  try {
    final delta = Delta.fromJson(deltaData);
    final buffer = StringBuffer();

    for (final op in delta.toList()) {
      if (op.data is String) {
        final text = op.data as String;
        if (!text.contains('[[IMAGE')) {
          buffer.write(text);
        }
      } else if (op.data is Map) {
        final data = op.data as Map;
        if (data.containsKey('image')) {
          buffer.write('\n');
        } else if (data.containsKey('insert') && data['insert'] is String) {
          final text = data['insert'] as String;
          if (!text.contains('[[IMAGE')) {
            buffer.write(text);
          }
        }
      }
    }

    return _collapsePreviewWhitespace(buffer.toString());
  } catch (_) {
    return _manualExtractText(deltaData);
  }
}

/// Manual text extraction as fallback
String _manualExtractText(dynamic data) {
  if (data is List) {
    final buffer = StringBuffer();
    for (final item in data) {
      if (item is Map) {
        if (item.containsKey('insert')) {
          final insert = item['insert'];
          if (insert is String) {
            if (!insert.contains('[[IMAGE')) {
              buffer.write(insert);
            }
          } else if (insert is Map) {
            if (!insert.containsKey('image')) {
              buffer.write(' ');
            }
          }
        }
      }
    }
    return _collapsePreviewWhitespace(buffer.toString());
  }

  return _collapsePreviewWhitespace(data.toString());
}
