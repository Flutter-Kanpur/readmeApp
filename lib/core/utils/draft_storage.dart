import 'package:shared_preferences/shared_preferences.dart';

class DraftEntry {
  const DraftEntry({
    required this.title,
    required this.content,
    required this.savedAt,
  });

  /// Title typed in the editor (may be empty if user only wrote content).
  final String title;

  /// Raw stored content (Quill delta JSON or HTML — same format as Supabase).
  final String content;

  /// When the draft was last saved. Null if we never recorded a timestamp.
  final DateTime? savedAt;

  bool get isEmpty => title.trim().isEmpty && content.trim().isEmpty;
}

class DraftStorage {
  static const _draftTitleKey = 'draft_title';
  static const _draftContentKey = 'draft_content';
  static const _draftSavedAtKey = 'draft_saved_at';

  static Future<bool> hasSavedDraft() async {
    final entry = await getDraft();
    return entry != null && !entry.isEmpty;
  }

  static Future<DraftEntry?> getDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final title = prefs.getString(_draftTitleKey) ?? '';
    final content = prefs.getString(_draftContentKey) ?? '';
    if (title.trim().isEmpty && content.trim().isEmpty) return null;

    final savedAtIso = prefs.getString(_draftSavedAtKey);
    final savedAt =
        savedAtIso != null ? DateTime.tryParse(savedAtIso) : null;

    return DraftEntry(
      title: title,
      content: content,
      savedAt: savedAt,
    );
  }

  static Future<void> setSavedAt(DateTime when) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftSavedAtKey, when.toIso8601String());
  }

  static Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftTitleKey);
    await prefs.remove(_draftContentKey);
    await prefs.remove(_draftSavedAtKey);
  }
}
