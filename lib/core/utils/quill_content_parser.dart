import 'dart:convert';
import 'package:dart_quill_delta/dart_quill_delta.dart';

/// Parses blog content (Quill Delta JSON or HTML) and returns plain text
String parseQuillContent(dynamic content) {
  if (content == null) return '';

  if (content is String) {
    final trimmed = content.trim();
    // Quill Delta JSON
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(content);
        return _extractTextFromDelta(decoded);
      } catch (e) {
        return content;
      }
    }
    // HTML (e.g. from another editor or export)
    if (trimmed.contains('<') && trimmed.contains('>')) {
      return _stripHtmlToPlainText(content);
    }
    return content;
  }

  if (content is List || content is Map) {
    return _extractTextFromDelta(content);
  }

  return content.toString();
}

/// Strip HTML tags and base64 image data to plain text
String _stripHtmlToPlainText(String html) {
  String text = html;
  // Remove base64 image data (data:image/...;base64,...) so it doesn't flood the output
  text = text.replaceAll(
    RegExp(r'data:image/[^;]+;base64,[A-Za-z0-9+/=]+', caseSensitive: false),
    '',
  );
  // Remove <img ...> tags (including broken ones)
  text = text.replaceAll(RegExp(r'<img[^>]*>', caseSensitive: true), ' ');
  // Remove all other HTML tags
  text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
  // Decode common entities
  text = text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"');
  // Collapse whitespace and trim
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return text;
}

/// Extracts plain text from Quill Delta format
String _extractTextFromDelta(dynamic deltaData) {
  if (deltaData == null) return '';
  
  try {
    // Create Delta from the data
    final delta = Delta.fromJson(deltaData);
    final buffer = StringBuffer();
    
    // Iterate through operations and extract text
    for (final op in delta.toList()) {
      if (op.data is String) {
        final text = op.data as String;
        // Skip image placeholders like "[[IMAGE_0]]"
        if (!text.contains('[[IMAGE_')) {
          buffer.write(text);
        }
      } else if (op.data is Map) {
        // Handle embedded content (images, etc.)
        final data = op.data as Map;
        if (data.containsKey('image')) {
          // Skip image content for plain text extraction
          buffer.write('\n');
        } else if (data.containsKey('insert') && data['insert'] is String) {
          // Some nested insert operations
          final text = data['insert'] as String;
          if (!text.contains('[[IMAGE_')) {
            buffer.write(text);
          }
        }
      }
    }
    
    return buffer.toString().trim();
  } catch (e) {
    // If Delta parsing fails, try manual extraction
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
            // Skip image placeholders like "[[IMAGE_0]]"
            if (!insert.contains('[[IMAGE_')) {
              buffer.write(insert);
            }
          } else if (insert is Map) {
            // Skip embedded content like images
            if (!insert.containsKey('image')) {
              buffer.write('\n');
            }
          }
        }
      }
    }
    return buffer.toString().trim();
  }
  
  return data.toString();
}
