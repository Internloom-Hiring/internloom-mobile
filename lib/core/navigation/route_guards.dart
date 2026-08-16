import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/profile/provider/profile_provider.dart';

/// Static guard checks used by AppRouter's redirect callback.
///
/// Every method reads live state from the widget tree — callers pass [context]
/// and these helpers do the reads so the router redirect stays readable.
///
/// ⚠️  Always read `AuthBloc`, NOT `AuthenticationBloc` — the latter is an
///     unused duplicate left in the repository from Sprint 1 and is not wired
///     to `main.dart`.
class RouteGuards {
  RouteGuards._();

  // ─── AuthGuard ────────────────────────────────────────────────────────────

  /// Returns true when a valid Supabase session is active.
  ///
  /// Source: [AuthBloc] — reads the current bloc state.
  /// DB dependency: Supabase `auth.users` (session managed by supabase_flutter).
  static bool isAuthenticated(BuildContext context) {
    final state = context.read<AuthBloc>().state;
    return state is Authenticated;
  }

  // ─── RoleGuard ────────────────────────────────────────────────────────────

  /// Returns the user's role from Supabase user metadata.
  ///
  /// Source: [AuthBloc] — reads the [Authenticated] user's `userMetadata`.
  /// DB dependency: `auth.users.raw_user_meta_data -> 'role'`.
  ///   Expected values: 'student' | 'company' | 'admin'.
  ///   Developer 2 must write this key during sign-up / OAuth registration.
  ///   Falls back to 'student' so Sprint 1 accounts (no metadata) keep working.
  static String getUserRole(BuildContext context) {
    final state = context.read<AuthBloc>().state;
    if (state is Authenticated) {
      return state.user.userMetadata?['role'] as String? ?? 'student';
    }
    return 'student';
  }

  /// Returns true when the signed-in user has the expected [role].
  static bool hasRole(BuildContext context, String role) =>
      getUserRole(context) == role;

  // ─── ProfileCompletionGuard ───────────────────────────────────────────────

  /// Returns true when the student's profile meets the guided-setup minimum
  /// (Education + ≥ 3 skills + Resume — see [StudentProfile.hasGuidedSetupMinimum]).
  ///
  /// Source: [ProfileProvider] — reads the in-memory profile loaded from the
  ///   `students` table by [ProfileService].
  /// DB dependency: `public.students` (course, branch, college_name,
  ///   graduation_year, cgpa, skills, resume_path columns).
  static bool isStudentProfileComplete(BuildContext context) {
    return context.read<ProfileProvider>().profile?.hasGuidedSetupMinimum ?? false;
  }

  /// Returns true when [ProfileProvider] has finished loading (not initial or
  /// loading) — used to avoid premature redirect decisions.
  static bool isProfileLoaded(BuildContext context) {
    final state = context.read<ProfileProvider>().loadState;
    return state == ProfileLoadState.loaded || state == ProfileLoadState.error;
  }

  // ─── CompanyApprovalGuard ─────────────────────────────────────────────────

  /// Returns the company's approval status.
  ///
  /// Source: [AuthBloc] user metadata (placeholder).
  /// Real DB dependency: `public.companies.approval_status`.
  ///   ⚠️  The `companies` table does NOT yet exist in the codebase.
  ///   Developer 4 must create the table and, once ready, replace this stub
  ///   with a real CompanyProvider / service call.
  ///   For now we read from user metadata so Developer 4 can mock via Supabase
  ///   dashboard without blocking this sprint.
  static String getCompanyApprovalStatus(BuildContext context) {
    final state = context.read<AuthBloc>().state;
    if (state is Authenticated) {
      return state.user.userMetadata?['company_approval_status'] as String?
          ?? 'approved'; // default allows devs to test without metadata set
    }
    return 'pending';
  }

  /// Returns true when the company account has been approved.
  static bool isCompanyApproved(BuildContext context) =>
      getCompanyApprovalStatus(context) == 'approved';
}
