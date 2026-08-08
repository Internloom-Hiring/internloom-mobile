# internloom-mobile

Mobile app for internloom.com — Flutter.

## Status

Two workstreams are merged into this repo so far: **Authentication** (original) and **Student Profile / Profile Filling** (merged in 2026-08-09). Company Side and a final UI Design pass are still pending from other teammates.

## What's implemented

### Authentication — `lib/features/auth/`

Email/password login & registration, forgot/update password, Google & LinkedIn OAuth, deep-link handling for OAuth callbacks and password recovery. State management: `flutter_bloc` (`AuthBloc`/`AuthState`/`AuthEvent`), with `AuthRepository` wrapping Supabase Auth directly.

### Student Profile — `lib/features/profile/` (merged 2026-08-09)

Full profile-filling flow, matching the real Supabase `students` table exactly (confirmed against the live schema, not guessed):

- **Guided setup** (Education → Skills → Resume) for first-time students, then a section-by-section edit flow for everything else — About, Education, Skills, Projects, Certifications, Achievements, Resume, LinkedIn, and College Verification (email + ID upload).
- **State management**: `provider`/`ChangeNotifier` (`ProfileProvider`), nested inside Auth's `BlocProvider` in `main.dart` — the two state-management approaches coexist without conflict.
- **RLS-hardened writes**: every read/write derives identity from the live Supabase session (`AppSupabase.currentUserId`) rather than any passed-in id, and `upsertProfile()` refuses client-side if a profile's id doesn't match the session. Permission-denied failures are a distinct error (`ProfileWriteDeniedException`), surfaced differently in the UI than a generic network failure.
- **Private file storage**: resume and college-ID uploads go through a private bucket with signed URLs (1-hour expiry) — never a public URL.
- **Integration point**: `SplashScreen`, `LoginScreen`, and `RegisterScreen` all route into `ProfileGate` (`features/profile/presentation/screens/profile_gate.dart`) on successful auth, which loads the student's profile and routes to Guided Setup or the main Profile view depending on completeness.

## Setup

1. `flutter pub get`
2. Create a `.env` file in the project root (already gitignored via `.env*`) with your real Supabase project's credentials:
   ```
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-actual-anon-key
   ```
3. `flutter run`

## Verification status (as of 2026-08-09)

- `flutter analyze` — clean. (Without a real `.env`, you'll see one expected `asset_does_not_exist` warning for `.env` itself — not a code issue, just a missing local secrets file.)
- `flutter test` — runs Authentication's existing four tests (`auth_bloc_test.dart`, `error_formatter_test.dart`, `validators_test.dart`, `widget_test.dart`). There's no dedicated test coverage for the profile feature yet.
- Merge was verified statically (import resolution, brace/paren balance, duplicate-class checks across all `.dart` files) since no Flutter SDK was available in the environment doing the merge — `flutter analyze` on a real machine is the first actual compiler pass this code has been through, and it came back clean.

## Known open items

1. **`AppColors` / `Validators` name collisions.** `lib/constants/theme.dart` (profile feature's placeholder palette, values matched to the real one) duplicates `lib/core/constants/app_colors.dart`'s class name; `lib/features/profile/utils/validators.dart` (field validation) duplicates `lib/core/utils/validators.dart`'s class name (email/password validation — different purpose). No file currently imports both sides of either pair, so it compiles fine, but the profile feature should eventually be repointed at the real `core/` versions instead of carrying its own copies.
2. **Schema conflict, flagged not resolved.** An earlier "Flutter Core Architecture" planning doc proposed a `profiles` table with JSONB blobs; the profile feature instead targets the real, confirmed `students` table (separate `id`/`profile_id`, flat typed columns), since that's what's actually deployed. See `supabase/student_profiles_schema.sql` for the full note — needs a team decision to reconcile the doc with reality.
3. **`verification_status` / `verification_method` enum values are placeholder guesses** (`'pending'/'verified'/'rejected'`, `'none'/'college_email'/'college_id'`) — need confirming against the actual Postgres enum definitions.
4. **Company Side** — candidate list screens and the RLS select policy allowing companies to read `students` rows — not built yet.
5. **Final visual design** — `lib/constants/theme.dart`'s palette matches the real brand colors by value but isn't literally the same shared object; a UI Design pass to consolidate onto one theme is still pending.
