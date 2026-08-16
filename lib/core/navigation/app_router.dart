import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';

// Auth bloc
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';

// Auth screens
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/update_password_screen.dart';

// Profile provider & screens
import '../../features/profile/provider/profile_provider.dart';
import '../../features/profile/presentation/screens/guided_setup_screen.dart';
import '../../features/profile/presentation/screens/profile_view_screen.dart';
import '../../features/profile/presentation/screens/edit_headline_photo_screen.dart'; // EditBasicInfoScreen
import '../../features/profile/presentation/screens/edit_about_screen.dart';
import '../../features/profile/presentation/screens/edit_education_screen.dart';
import '../../features/profile/presentation/screens/edit_college_verification_screen.dart';
import '../../features/profile/presentation/screens/edit_skills_screen.dart';
import '../../features/profile/presentation/screens/edit_projects_screen.dart';
import '../../features/profile/presentation/screens/edit_certifications_screen.dart';
import '../../features/profile/presentation/screens/edit_achievements_screen.dart';
import '../../features/profile/presentation/screens/edit_resume_screen.dart';
import '../../features/profile/presentation/screens/edit_social_links_screen.dart'; // EditLinkedinScreen

/// Central router configuration for InternLoom Mobile.
///
/// ──────────────────────────────────────────────────────────────────
/// CRITICAL DESIGN NOTE — why the redirect avoids context.read()
/// ──────────────────────────────────────────────────────────────────
/// GoRouter's `redirect` callback receives a BuildContext that is the
/// router's own navigator context (inside MaterialApp.router). Calling
/// `context.read<AuthBloc>()` from there is unreliable: if the
/// InheritedWidget lookup walks up past the router boundary it can
/// throw ProviderNotFoundException, silently swallowed by go_router,
/// leaving the spinner frozen forever.
///
/// The fix: pass [authBloc] and [profileProvider] directly into
/// [buildRouter]. The redirect closes over those references and reads
/// their state directly — no BuildContext required in the redirect.
///
/// Guard execution order for every redirect:
///   1. AuthGuard  — unauthenticated → /login
///   2. RoleGuard  — wrong-role path → role's home
///   3. ProfileCompletionGuard — incomplete student → /student/setup
///   4. CompanyApprovalGuard   — unapproved company → /company/approval-wait
class AppRouter {
  AppRouter._();

  /// Call ONCE — store the result (e.g. in a [StatefulWidget]'s state)
  /// and pass to [MaterialApp.router]. Never call inside a [Builder]
  /// that can rebuild, or a new router will be created on every frame.
  static GoRouter buildRouter({
    required AuthBloc authBloc,
    required ProfileProvider profileProvider,
  }) {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: false,
      // Refresh whenever AuthBloc OR ProfileProvider changes so the
      // redirect re-evaluates after login, logout, and profile load.
      refreshListenable: _RouterRefreshListenable(authBloc, profileProvider),
      redirect: (context, state) => _globalRedirect(authBloc, profileProvider, state),
      routes: _buildRoutes(),
    );
  }

  // ─── Global redirect ──────────────────────────────────────────────────────

  static String? _globalRedirect(
    AuthBloc authBloc,
    ProfileProvider profileProvider,
    GoRouterState state,
  ) {
    final authState = authBloc.state;
    final path = state.uri.path;

    // Wait for the first session check before doing anything.
    if (authState is AuthInitial || authState is AuthLoading) return null;

    final authenticated = authState is Authenticated;

    // ── 1. AuthGuard ─────────────────────────────────────────────────────────
    if (!authenticated) {
      const publicPaths = <String>[
        '/',
        '/login',
        '/register',
        '/forgot-password',
        '/update-password',
      ];
      if (!publicPaths.contains(path)) return '/login';
      return null; // already on a public route — leave it alone
    }

    // ── 2. RoleGuard ─────────────────────────────────────────────────────────
    // Dart flow analysis promotes authState → Authenticated here because the
    // AuthGuard block above returns early for every non-Authenticated state.
    final role = authState.user.userMetadata?['role'] as String? ?? 'student';

    // Authenticated users on a pure-auth route → home for their role.
    const authOnlyPaths = <String>['/login', '/register', '/'];
    if (authOnlyPaths.contains(path)) {
      return role == 'company' ? '/company/dashboard' : '/student/profile';
    }

    if (role == 'company') {
      if (path.startsWith('/student')) return '/company/dashboard';

      // ── 4. CompanyApprovalGuard ───────────────────────────────────────────
      // TODO(Dev4): replace metadata stub with a real CompanyProvider read
      // once the public.companies table is in place.
      final approvalStatus =
          authState.user.userMetadata?['company_approval_status'] as String? ?? 'approved';
      final approved = approvalStatus == 'approved';
      if (!approved && path != '/company/approval-wait') return '/company/approval-wait';
      if (approved && path == '/company/approval-wait') return '/company/dashboard';
      return null;
    }

    // role == 'student' (default)
    if (path.startsWith('/company')) return '/student/profile';

    // ── 3. ProfileCompletionGuard ─────────────────────────────────────────────
    // Only enforce once the profile has actually finished loading so we don't
    // bounce a user to /setup on a transient "not yet loaded" false-negative.
    final profileLoaded = profileProvider.loadState == ProfileLoadState.loaded ||
        profileProvider.loadState == ProfileLoadState.error;

    if (profileLoaded) {
      final complete = profileProvider.hasGuidedSetupMinimum;
      if (!complete && path != '/student/setup') return '/student/setup';
      if (complete && path == '/student/setup') return '/student/profile';
    }

    return null;
  }

  // ─── Route tree ───────────────────────────────────────────────────────────

  static List<RouteBase> _buildRoutes() => [
        GoRoute(
          path: '/',
          name: RouteNames.splash,
          builder: (context, state) => const SplashScreen(),
        ),

        // Auth
        GoRoute(
          path: '/login',
          name: RouteNames.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: RouteNames.register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          name: RouteNames.forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/update-password',
          name: RouteNames.updatePassword,
          builder: (context, state) => const UpdatePasswordScreen(),
        ),

        // Student — guided setup
        GoRoute(
          path: '/student/setup',
          name: RouteNames.studentSetup,
          builder: (context, state) => const GuidedSetupScreen(),
        ),

        // Student — profile (parent) + edit sub-routes (pushed on top)
        GoRoute(
          path: '/student/profile',
          name: RouteNames.studentProfile,
          builder: (context, state) => const ProfileViewScreen(),
          routes: [
            GoRoute(
              path: 'edit-basic',
              name: RouteNames.studentEditBasic,
              builder: (context, state) => const EditBasicInfoScreen(),
            ),
            GoRoute(
              path: 'edit-about',
              name: RouteNames.studentEditAbout,
              builder: (context, state) => const EditAboutScreen(),
            ),
            GoRoute(
              path: 'edit-education',
              name: RouteNames.studentEditEducation,
              builder: (context, state) => const EditEducationScreen(),
            ),
            GoRoute(
              path: 'edit-verification',
              name: RouteNames.studentEditVerification,
              builder: (context, state) => const EditCollegeVerificationScreen(),
            ),
            GoRoute(
              path: 'edit-skills',
              name: RouteNames.studentEditSkills,
              builder: (context, state) => const EditSkillsScreen(),
            ),
            GoRoute(
              path: 'edit-projects',
              name: RouteNames.studentEditProjects,
              builder: (context, state) => const EditProjectsScreen(),
            ),
            GoRoute(
              path: 'edit-certifications',
              name: RouteNames.studentEditCertifications,
              builder: (context, state) => const EditCertificationsScreen(),
            ),
            GoRoute(
              path: 'edit-achievements',
              name: RouteNames.studentEditAchievements,
              builder: (context, state) => const EditAchievementsScreen(),
            ),
            GoRoute(
              path: 'edit-resume',
              name: RouteNames.studentEditResume,
              builder: (context, state) => const EditResumeScreen(),
            ),
            GoRoute(
              path: 'edit-linkedin',
              name: RouteNames.studentEditLinkedin,
              builder: (context, state) => const EditLinkedinScreen(),
            ),
          ],
        ),

        // Company — placeholders for Developer 4
        GoRoute(
          path: '/company/dashboard',
          name: RouteNames.companyDashboard,
          builder: (context, state) => const _PlaceholderScreen(
            title: 'Company Dashboard',
            message: 'Company dashboard — Developer 4 will implement this screen.',
          ),
        ),
        GoRoute(
          path: '/company/approval-wait',
          name: RouteNames.companyApprovalWait,
          builder: (context, state) => const _PlaceholderScreen(
            title: 'Pending Approval',
            message: 'Your company account is pending approval by an administrator.',
          ),
        ),
      ];
}

// ─── Combined refresh listenable ──────────────────────────────────────────────

/// Makes [GoRouter] re-run its redirect whenever [AuthBloc] emits a new
/// state OR [ProfileProvider] notifies (e.g. after profile finishes loading).
///
/// Without the [ProfileProvider] subscription the ProfileCompletionGuard
/// never fires after the initial redirect because the redirect sees
/// "profile not loaded" and returns null — only when the profile finishes
/// loading and notifies does the redirect get a second chance to evaluate.
class _RouterRefreshListenable extends ChangeNotifier {
  _RouterRefreshListenable(AuthBloc authBloc, ProfileProvider profileProvider) {
    // Subscribe to AuthBloc state stream.
    authBloc.stream.listen((_) => notifyListeners());
    // Subscribe to ProfileProvider change notifications.
    profileProvider.addListener(notifyListeners);
  }
}

// ─── Placeholder screen ───────────────────────────────────────────────────────

/// Temporary destination for company routes not yet implemented by Developer 4.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
