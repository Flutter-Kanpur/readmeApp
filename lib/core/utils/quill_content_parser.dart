import 'dart:convert';
import 'package:dart_quill_delta/dart_quill_delta.dart';

/// Parses Quill Delta JSON content and extracts plain text
/// Handles both JSON strings and already parsed JSON objects
String parseQuillContent(dynamic content) {
  if (content == null) return '';
  
  // If content is already a plain string (not JSON), return it as is
  if (content is String) {
    // Check if it's a JSON string
    if (content.trim().startsWith('[') || content.trim().startsWith('{')) {
      try {
        // Try to parse as JSON
        final decoded = jsonDecode(content);
        return _extractTextFromDelta(decoded);
      } catch (e) {
        // If parsing fails, it might be plain text, return as is
        return content;
      }
    } else {
      // It's already plain text
      return content;
    }
  }
  
  // If content is already a List or Map (parsed JSON), extract text directly
  if (content is List || content is Map) {
    return _extractTextFromDelta(content);
  }
  
  return content.toString();
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
