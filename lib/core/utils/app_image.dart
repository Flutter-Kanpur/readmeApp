import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
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

/// Optionally rewrites Supabase Storage public URLs to the image transform
/// endpoint. Disabled by default because transforms often fail on free plans
/// and for SVG/community logos, which made images appear broken.
String optimizeStorageImageUrl(
  String url, {
  int? width,
  int? height,
  int quality = 80,
  bool enableTransform = false,
}) {
  if (!enableTransform || !isNetworkImageUrl(url)) return url;

  final uri = Uri.parse(url);
  const objectPrefix = '/storage/v1/object/public/';
  if (!uri.path.contains(objectPrefix)) return url;

  final lowerPath = uri.path.toLowerCase();
  final isRaster = lowerPath.endsWith('.jpg') ||
      lowerPath.endsWith('.jpeg') ||
      lowerPath.endsWith('.png') ||
      lowerPath.endsWith('.webp') ||
      lowerPath.endsWith('.gif');
  if (!isRaster) return url;

  final renderPath = uri.path.replaceFirst(
    objectPrefix,
    '/storage/v1/render/image/public/',
  );
  final params = <String, String>{
    ...uri.queryParameters,
    'quality': '$quality',
  };
  if (width != null) params['width'] = '$width';
  if (height != null) params['height'] = '$height';

  return uri.replace(path: renderPath, queryParameters: params).toString();
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

ImageProvider? imageProviderFromSource(
  String? source, {
  int? width,
  int? height,
}) {
  if (source == null || source.isEmpty) return null;

  if (isDataUriImage(source)) {
    final bytes = decodeDataUriImage(source);
    if (bytes != null) return MemoryImage(bytes);
    return null;
  }

  if (isNetworkImageUrl(source)) {
    return CachedNetworkImageProvider(
      source.trim(),
      maxWidth: width,
      maxHeight: height,
    );
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

  int? get _renderWidth {
    final value = width;
    if (value == null || !value.isFinite || value <= 0) return null;
    return (value * 2).round();
  }

  int? get _renderHeight {
    final value = height;
    if (value == null || !value.isFinite || value <= 0) return null;
    return (value * 2).round();
  }

  @override
  Widget build(BuildContext context) {
    final rawSource = source;
    if (rawSource == null || rawSource.isEmpty) {
      return placeholder ?? const SizedBox.shrink();
    }

    if (isDataUriImage(rawSource)) {
      final provider = imageProviderFromSource(rawSource);
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

    if (isNetworkImageUrl(rawSource)) {
      // Use the original public URL. Disk cache still cuts repeat egress;
      // render transforms were breaking community logos / many storage files.
      return CachedNetworkImage(
        imageUrl: rawSource.trim(),
        fit: fit,
        width: width,
        height: height,
        memCacheWidth: _renderWidth,
        memCacheHeight: _renderHeight,
        placeholder: (_, __) =>
            placeholder ??
            SizedBox(
              width: width,
              height: height,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        errorWidget: (_, __, ___) =>
            placeholder ?? const Icon(Icons.broken_image),
      );
    }

    final provider = imageProviderFromSource(rawSource);
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
