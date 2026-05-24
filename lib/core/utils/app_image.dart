import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool isDataUriImage(String source) {
  return source.trim().toLowerCase().startsWith('data:image/');
}

bool isNetworkImageUrl(String source) {
  final trimmed = source.trim();
  if (trimmed.startsWith('//')) return true;

  final uri = Uri.tryParse(trimmed);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

/// Normalizes image sources from Supabase storage paths, protocol-relative URLs, etc.
String resolveInlineImageSource(
  String source, {
  List<String>? imageUrls,
  String? Function(String storagePath)? storagePathToUrl,
}) {
  var value = source.trim();
  if (value.isEmpty) return value;

  if (value.startsWith('//')) {
    value = 'https:$value';
  }

  final placeholderMatch = RegExp(r'^\[\[IMAGE_?(\d+)\]\]$').firstMatch(value);
  if (placeholderMatch != null) {
    final index = int.tryParse(placeholderMatch.group(1)!);
    if (imageUrls != null &&
        index != null &&
        index >= 0 &&
        index < imageUrls.length) {
      return imageUrls[index];
    }
    return '';
  }

  if (isDataUriImage(value) || isNetworkImageUrl(value)) {
    return value;
  }

  if (storagePathToUrl != null) {
    return storagePathToUrl(value) ?? value;
  }

  return value;
}

/// Resolves cover/inline image paths from Supabase storage or returns the URL as-is.
String? resolveBlogImageUrl(
  String? source, {
  String? Function(String storagePath)? storagePathToUrl,
}) {
  if (source == null || source.trim().isEmpty) return null;
  final resolved = resolveInlineImageSource(
    source,
    storagePathToUrl: storagePathToUrl,
  );
  return resolved.isEmpty ? null : resolved;
}

Uint8List? decodeDataUriImage(String dataUri) {
  try {
    final commaIndex = dataUri.indexOf(',');
    if (commaIndex == -1) return null;
    return base64Decode(dataUri.substring(commaIndex + 1).trim());
  } catch (_) {
    return null;
  }
}

/// Resolves avatars, cover images, and other sources that may be http(s),
/// data URIs, or local file paths.
ImageProvider? imageProviderFromSource(String? source) {
  if (source == null || source.isEmpty) return null;

  if (isDataUriImage(source)) {
    final bytes = decodeDataUriImage(source);
    if (bytes != null) return MemoryImage(bytes);
    return null;
  }

  if (isNetworkImageUrl(source)) {
    return NetworkImage(source);
  }

  if (!kIsWeb) {
    final file = File(source);
    if (file.existsSync()) return FileImage(file);
  }

  return null;
}

/// For [FlutterQuillEmbeds] image embeds (drafts may store data URIs).
ImageProvider? quillImageProviderBuilder(BuildContext context, String source) {
  return imageProviderFromSource(source);
}

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.source,
    this.fit,
    this.width,
    this.height,
    this.placeholder,
  });

  final String? source;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final provider = imageProviderFromSource(source);
    if (provider == null) {
      return placeholder ?? const SizedBox.shrink();
    }

    return Image(
      image: provider,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) =>
          placeholder ?? const Icon(Icons.broken_image),
    );
  }
}
