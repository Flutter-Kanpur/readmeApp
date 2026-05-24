import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/quill_content_parser.dart';
import 'package:Readme/features/blog_detail/presentation/widgets/blog_code_block.dart';
import 'package:Readme/features/blog_detail/presentation/widgets/blog_inline_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:supabase_flutter/supabase_flutter.dart';
class BlogContentViewer extends StatefulWidget {
  const BlogContentViewer({
    super.key,
    required this.content,
    this.imageUrls,
    this.excludeImageUrl,
  });

  final String content;
  final List<String>? imageUrls;
  final String? excludeImageUrl;

  @override
  State<BlogContentViewer> createState() => _BlogContentViewerState();
}

class _BlogContentViewerState extends State<BlogContentViewer> {
  quill.QuillController? _controller;

  TextStyle get _bodySerif => TextStyle(
        fontFamily: 'ProductSans',
        fontSize: 20.sp,
        height: 1.65,
        color: AppColors.black,
      );

  TextStyle get _introSans => TextStyle(
    fontFamily: 'ProductSans',
        fontSize: 22.sp,
        height: 1.55,
        color: AppColors.subtitles,
        fontWeight: FontWeight.w400,
      );

  String get _normalizedContent => normalizeForRendering(widget.content);

  BlogContentFormat get _format => detectBlogContentFormat(widget.content);

  @override
  void initState() {
    super.initState();
    _initQuillControllerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant BlogContentViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.imageUrls != widget.imageUrls ||
        oldWidget.excludeImageUrl != widget.excludeImageUrl) {
      _controller?.dispose();
      _controller = null;
      _initQuillControllerIfNeeded();
    }
  }

  String _storagePublicUrl(String path) {
    return Supabase.instance.client.storage
        .from('blog_images')
        .getPublicUrl(path);
  }

  String? _resolveImageSrc(String? src) {
    if (src == null || src.isEmpty) return null;
    final resolved = resolveInlineImageSource(
      src,
      imageUrls: widget.imageUrls,
      storagePathToUrl: _storagePublicUrl,
    );
    return resolved.isEmpty ? null : resolved;
  }

  void _initQuillControllerIfNeeded() {
    if (_format != BlogContentFormat.quillDelta) return;

    try {
      final delta = contentToDelta(
        widget.content,
        imageUrls: widget.imageUrls,
        storagePathToUrl: _storagePublicUrl,
      );
      _controller = quill.QuillController(
        document: quill.Document.fromDelta(delta),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    } catch (_) {
      _controller = quill.QuillController(
        document: quill.Document()..insert(0, _normalizedContent),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_format) {
      case BlogContentFormat.html:
        return _buildHtmlView(_normalizedContent);
      case BlogContentFormat.markdown:
        final html = md.markdownToHtml(
          _normalizedContent,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );
        return _buildHtmlView(html);
      case BlogContentFormat.quillDelta:
        return _buildQuillView();
      case BlogContentFormat.plainText:
        return _buildPlainTextView();
    }
  }

  Widget _buildQuillView() {
    final controller = _controller;
    if (controller == null) return _buildPlainTextView();
    final contentWidth = MediaQuery.sizeOf(context).width - 48.w;

    return SizedBox(
      width: double.infinity,
      child: DefaultTextStyle(
        style: _bodySerif,
        child: quill.QuillEditor.basic(
          controller: controller,
          config: quill.QuillEditorConfig(
            scrollable: false,
            padding: EdgeInsets.zero,
            showCursor: false,
            enableInteractiveSelection: true,
            maxContentWidth: contentWidth,
            customStyles: _quillStyles(context),
            embedBuilders: [
              _BlogImageEmbedBuilder(imageUrls: widget.imageUrls),
              ...FlutterQuillEmbeds.editorBuilders(
                imageEmbedConfig: const QuillEditorImageEmbedConfig(),
              ).where((b) => b.key != quill.BlockEmbed.imageType),
            ],
          ),
        ),
      ),
    );
  }

  quill.DefaultStyles _quillStyles(BuildContext context) {
    final base = quill.DefaultStyles.getInstance(context);

    return quill.DefaultStyles(
      h1: base.h1,
      h2: quill.DefaultTextBlockStyle(
        _introSans,
        base.h2!.horizontalSpacing,
        base.h2!.verticalSpacing,
        base.h2!.lineSpacing,
        base.h2!.decoration,
      ),
      h3: base.h3,
      paragraph: quill.DefaultTextBlockStyle(
        _bodySerif,
        base.paragraph!.horizontalSpacing,
        const quill.VerticalSpacing(0, 18),
        base.paragraph!.lineSpacing,
        base.paragraph!.decoration,
      ),
      lists: base.lists?.copyWith(style: _bodySerif),
      quote: quill.DefaultTextBlockStyle(
        _introSans,
        base.quote!.horizontalSpacing,
        base.quote!.verticalSpacing,
        base.quote!.lineSpacing,
        base.quote!.decoration,
      ),
      bold: base.bold?.merge(_bodySerif.copyWith(fontWeight: FontWeight.w700)),
      italic:
          base.italic?.merge(_bodySerif.copyWith(fontStyle: FontStyle.italic)),
      link: base.link,
      placeHolder: base.placeHolder,
    );
  }

  Widget _buildHtmlView(String html) {
    final blocks = prepareHtmlContentBlocks(
      html,
      imageUrls: widget.imageUrls,
      storagePathToUrl: _storagePublicUrl,
      excludeImageUrl: widget.excludeImageUrl,
    );
    if (blocks.isEmpty) return const SizedBox.shrink();

    final serifFamily = GoogleFonts.lora().fontFamily;
    final sansFamily = 'ProductSans';
    final htmlStyles = {
      'body': Style(
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
        fontFamily: sansFamily,
        fontSize: FontSize(18.sp),
        // lineHeight: const LineHeight(1.65),
        color: AppColors.black,
      ),
      'p': Style(
        margin: Margins.only(bottom: 18),
        fontFamily: sansFamily,
        fontSize: FontSize(18.sp),
        // lineHeight: const LineHeight(1.65),
      ),
      'figure': Style(margin: Margins.symmetric(vertical: 16)),
      'h1': Style(
        fontFamily: sansFamily,
        fontSize: FontSize(20.sp),
        fontWeight: FontWeight.w700,
        margin: Margins.only(bottom: 16, top: 8),
      ),
      'h2': Style(
        fontFamily: sansFamily,
        fontSize: FontSize(20.sp),
        // lineHeight: const LineHeight(1.55),
        color: AppColors.black,
        margin: Margins.only(bottom: 24),
      ),
      'h3': Style(
        fontFamily: sansFamily,
        fontSize: FontSize(18.sp),
        fontWeight: FontWeight.w600,
        color: AppColors.black,
        margin: Margins.only(bottom: 16, top: 8),
      ),
      'strong': Style(
        fontFamily: sansFamily,
        fontSize: FontSize(18.sp),
        fontWeight: FontWeight.w700,
      ),
      'b': Style(
        fontFamily: sansFamily,
        fontSize: FontSize(18.sp),
        fontWeight: FontWeight.w700,
      ),
      'em': Style(
        fontFamily: sansFamily,
        fontSize: FontSize(18.sp),
        fontStyle: FontStyle.italic,
      ),
      'i': Style(
        fontFamily: sansFamily,
        fontSize: FontSize(18.sp),
        fontStyle: FontStyle.italic,
      ),
      'ul': Style(
          fontFamily: sansFamily,
          margin: Margins.only(left: 8, bottom: 18)),
      'ol': Style(
          fontFamily: sansFamily,
          margin: Margins.only(left: 8, bottom: 18)),
      'li': Style(
        fontFamily: sansFamily,
        fontSize: FontSize(18.sp),
        // lineHeight: const LineHeight(1.65),
        margin: Margins.only(bottom: 10),
        display: Display.listItem,
      ),
      'code': Style(
        fontFamily: GoogleFonts.sourceCodePro().fontFamily,
        fontSize: FontSize(14.sp),
        backgroundColor: const Color(0xFFF9F9F9),
        padding: HtmlPaddings.symmetric(horizontal: 6, vertical: 2),
      ),
      'pre': Style(
        fontFamily: GoogleFonts.sourceCodePro().fontFamily,
        fontSize: FontSize(14.sp),
        backgroundColor: const Color(0xFFF9F9F9),
        padding: HtmlPaddings.symmetric(horizontal: 16, vertical: 20),
        margin: Margins.symmetric(vertical: 12),
        display: Display.block,
        whiteSpace: WhiteSpace.pre,
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final block in blocks)
          if (_isImageBlock(block))
            BlogInlineImage(source: _imageUrlFromBlock(block)!)
          else if (_isPreBlock(block))
            BlogCodeBlock(code: _codeFromPreBlock(block))
          else
            Html(
              data: block,
              doNotRenderTheseTags: const {
                'script',
                'style',
                'noscript',
                'figcaption',
              },
              style: htmlStyles,
            ),
      ],
    );
  }

  bool _isImageBlock(String block) {
    return RegExp(r'^<img\b', caseSensitive: false).hasMatch(block.trim());
  }

  bool _isPreBlock(String block) {
    return RegExp(r'^<pre\b', caseSensitive: false).hasMatch(block.trim());
  }

  String _codeFromPreBlock(String block) {
    var code = block.trim();
    code = code.replaceFirst(RegExp(r'^<pre\b[^>]*>', caseSensitive: false), '');
    code = code.replaceFirst(RegExp(r'</pre>$', caseSensitive: false), '');
    code = code.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    code = code.replaceAll(RegExp(r'<[^>]+>'), '');
    if (code.contains('&lt;') || code.contains('&amp;')) {
      code = normalizeForRendering(code);
    }
    return code.trim();
  }

  String? _imageUrlFromBlock(String block) {
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

  Widget _buildPlainTextView() {
    final paragraphs = _normalizedContent
        .split(RegExp(r'\n{2,}'))
        .where((p) => p.trim().isNotEmpty)
        .toList();

    if (paragraphs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          Text(
            paragraphs[i].trim(),
            softWrap: true,
            style: i == 0 ? _introSans : _bodySerif,
          ),
          if (i < paragraphs.length - 1) SizedBox(height: i == 0 ? 20.h : 18.h),
        ],
      ],
    );
  }
}

class _BlogImageEmbedBuilder extends quill.EmbedBuilder {
  _BlogImageEmbedBuilder({this.imageUrls});

  final List<String>? imageUrls;

  @override
  String get key => quill.BlockEmbed.imageType;

  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final rawSource = embedContext.node.value.data.toString();
    final resolved = resolveInlineImageSource(
      rawSource,
      imageUrls: imageUrls,
      storagePathToUrl: (path) => Supabase.instance.client.storage
          .from('blog_images')
          .getPublicUrl(path),
    );
    if (resolved.isEmpty) return const SizedBox.shrink();
    return BlogInlineImage(source: resolved);
  }
}
