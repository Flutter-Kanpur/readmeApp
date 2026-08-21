# ReadMe — Project Understanding & Review

_Reviewed: 2026-08-21 · Flutter blog app (`com.drishtant.readme`), v1.1.0+8_

---

## 1. What this project is

**ReadMe** is a Flutter blogging app (Medium-style) that runs **standalone** on the
Play Store / App Store *and* can be **embedded inside a host "Flutter Kanpur" app**.
Backend is **Supabase** (auth, Postgres, storage, edge functions). It ships OTA Dart
fixes via **Shorebird** and gates full-store upgrades with `upgrader`.

**Core features:** email + Google auth, home feed with category filters, article
detail (likes, views, comments/replies, follow, support), a rich blog editor with
drafts, author/user profiles, communities (with an admin dashboard + newsletters),
search, deep links to articles, and a privacy/legal section.

### Tech stack

| Area | Choice |
|---|---|
| Framework | Flutter (Dart `^3.10.4`, FVM-pinned) |
| Backend | Supabase (`supabase_flutter`), 3 edge functions |
| Routing | `go_router` (StatefulShellRoute + redirect-based auth) |
| Editor | `flutter_quill` + HTML interop (`flutter_html`, delta⇄HTML) |
| State | **None formal** — `setState` + global singletons + `ValueNotifier` |
| DI | **None** — repos constructed inline in widgets |
| OTA / updates | Shorebird + `upgrader` |
| Sizing / fonts | `flutter_screenutil`, `google_fonts` + bundled ProductSans |

**Scale:** 119 Dart files · ~18,000 LOC in `lib/` · feature-first layout.

---

## 2. What's done well ✅

- **Feature-first structure.** `lib/features/<feature>/{data,domain,presentation}` +
  `lib/core` + `lib/shared` is clean and easy to navigate.
- **Strong database security.** Migrations enable **RLS** on every table with correct
  per-user policies, and RPCs are `security definer` with `set search_path` and
  `revoke all ... from public` (`supabase/migrations/*`). This is textbook-correct.
- **Serious production thinking** for a solo/small project: Shorebird OTA, in-app
  upgrader, verified deep links (App Links / Universal Links), env validation with a
  graceful `ConfigErrorApp` fallback (`lib/main.dart:21`), and a dual standalone/embedded
  wiring model.
- **Egress-conscious backend.** An `excerpt` trigger and feed/engagement caches avoid
  pulling full article bodies into list views.
- **Secrets hygiene on the client.** `.env` is git-ignored; the Supabase **anon** key is
  publishable by design and safe in the client (protected by the RLS above).
- **Good docs.** `README.md` clearly explains env setup, deep links, and the Shorebird
  release/patch workflow. Nice UX polish too (custom page transitions, shimmer loaders).

---

## 3. Issues & suggestions (prioritized)

### 🔴 High priority

**H1 — Effectively zero test coverage, and the one test is broken.**
`test/widget_test.dart` is still the default Flutter *counter* smoke test — it looks for
`Icons.add` and text `'0'/'1'` that don't exist in this app, and `pumpWidget(MyApp())`
would throw anyway (needs Supabase + dotenv initialized). So across 18k LOC there is **no
real coverage**, and CI (if any) is testing a fiction.
→ Delete that test. Add unit tests for pure logic first — `quill_content_parser.dart`
(684 lines, high-risk), `relative_time.dart`, `blog_category_utils.dart`, the caches — then
widget tests for `BlogCard`, auth forms, etc. Wire `flutter test` into CI.

**H2 — No dependency injection / composition root.**
Repositories are `new`'d inside widgets, duplicated across screens:
`BlogRepositoryImpl(BlogRemoteDatasource(ReadmeSupabase.client))` in
[home_screen.dart:47](lib/features/home_page/presentation/pages/home_screen.dart#L47),
[profile_screen.dart:35](lib/features/profile_page/presentation/screens/profile_screen.dart#L35),
and [author_profile_screen.dart:28](lib/features/profile_page/presentation/screens/author_profile_screen.dart#L28).
This hard-couples UI to concrete implementations and makes H1 (testing) much harder.
→ Introduce a single composition root — `get_it` (simplest) or `riverpod` providers —
and inject repositories. Widgets should depend on the `BlogRepository` interface, not build it.

**H3 — No state-management strategy.**
State lives in `setState` + **global mutable singletons** (`BlogFeedCache.instance`,
`BlogEngagementStore.instance`, `BlogLikeCache`) + scattered `ValueNotifier`s. This works
today but makes data flow implicit, hard to test, and prone to stale-UI/consistency bugs as
features grow.
→ Adopt one approach and apply it consistently. `riverpod` pairs naturally with the
existing repository split and would subsume both H2 and H3.

### 🟡 Medium priority

**M1 — "Clean architecture" is only half-applied.** Layer usage is inconsistent:

| Feature | data | domain (repo iface) | use_cases |
|---|:--:|:--:|:--:|
| home_page | ✅ | ✅ | ✖ |
| create_blog_page | ✅ | ✅ | ✅ |
| blog_detail | ✅ | entities only | ✖ |
| communities | ✅ | entities only | ✖ |
| profile_page | ✅ | entities only | ✖ |
| search | ✅ | ✖ | ✖ |
| auth | presentation only | — | — |

Only 2 features define repository interfaces; only 1 has use cases. Elsewhere widgets call
datasources directly. The folders imply a contract the code doesn't keep.
→ Pick a lane: either (a) commit to repository interfaces everywhere data is fetched, or
(b) drop the ceremony and let presentation talk to datasources uniformly. Consistency
matters more than which one you choose.

**M2 — God files.**
[community_dashboard_screen.dart](lib/features/communities/presentation/pages/community_dashboard_screen.dart)
is **1,893 lines** with 11 widget classes and ~30 methods in one `State` (logo upload,
members, invites, join requests, newsletters, tabs — all in one place). Others are large too
(`my_drafts_screen` 664, `edit_profile_screen` 615, `create_blog_screen` 599).
→ Split the dashboard by responsibility (one file per tab/section widget) and lift data
loading out of the widget into a controller/notifier. Target a few hundred lines per file.

**M3 — Errors are swallowed silently; no crash reporting.**
25 of 88 `catch` blocks are empty / `catch (_) {}` (e.g. `quill_content_parser.dart` has
several `catch (_) {}`). Real failures disappear with no log and no user feedback, and there
is **no crash/error reporting** dependency (Sentry / Crashlytics) anywhere.
→ At minimum log swallowed errors behind a debug flag; surface user-facing failures as
snackbars/retry. Add Sentry or Firebase Crashlytics — critical once Shorebird is pushing OTA
code you can't see crash in the store console.

**M4 — Local tooling state committed to git.**
`supabase/.temp/*` (including `linked-project.json`, `project-ref`, `pooler-url`) is tracked,
**and there's a duplicate nested `supabase/supabase/.temp/`** from an accidental second
`supabase init`.
→ `git rm -r --cached supabase/.temp supabase/supabase`, delete the nested folder, and add
`supabase/.temp/` to `.gitignore`.

### 🟢 Low priority / quick wins

- **L1 — Dead code:** `lib/features/home_page/data/datasource/dummy_blogs.dart` is
  unreferenced. Delete it.
- **L2 — Stray `print()`** at
  [blog_view_datasource.dart:81](lib/features/blog_detail/data/datasource/blog_view_datasource.dart#L81).
  Use `debugPrint`/a logger or remove.
- **L3 — Bare lint config.** `analysis_options.yaml` only includes `flutter_lints` defaults.
  Consider `very_good_analysis` or enabling rules like `prefer_relative_imports` /
  `always_use_package_imports` — imports currently mix both styles
  (`home_screen.dart` uses `../../../../shared/...` *and* `package:Readme/...`).
- **L4 — Package name `Readme`** (capitalized) is non-idiomatic; Dart convention is
  `snake_case` (`readme`). It's why every import reads `package:Readme/...`. Cosmetic, but
  worth fixing before it spreads further.
- **L5 — `.env.example` ships a real project URL + anon key** rather than placeholders.
  Safe (anon key is public), but an example file should be a fill-in template.
- **L6 — Boilerplate leftover:** `pubspec.yaml` description is still `"A new Flutter project."`.
- **L7 — Editor builds HTML by string concat** without escaping the URL in
  `insertLink` ([blog_editor_controller.dart:48](lib/features/create_blog_page/presentation/controllers/blog_editor_controller.dart#L48)).
  Low risk (author's own content, `flutter_html` doesn't execute JS) but worth escaping.

---

## 4. Suggested order of attack

1. **Delete the fake test + add a real test harness** (H1) — unblocks everything else.
2. **Add DI + a state solution together** via `riverpod` or `get_it` (H2, H3).
3. **Add crash reporting and stop swallowing errors** (M3) — cheap, high visibility.
4. **Clean the repo**: `.temp` files, dead code, `print`, description (M4, L1, L2, L6).
5. **Refactor the dashboard god-file** and standardize the layer pattern (M2, M1).

Nothing here is alarming — the security and release engineering are genuinely above average
for an app this size. The gaps are the classic "moved fast" ones: **tests, DI, consistent
state, and error visibility.** Closing those is what turns this from a working app into a
maintainable one.
