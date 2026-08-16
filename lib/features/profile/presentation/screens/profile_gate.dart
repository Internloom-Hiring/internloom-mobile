import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../provider/profile_provider.dart';
import 'guided_setup_screen.dart';
import 'profile_view_screen.dart';

/// Loads the current student's profile and routes to Guided Setup if
/// the minimum isn't met yet, or straight to the profile view if it
/// is — Section 2.4.
///
/// THIS is the integration point Authentication's repo already
/// anticipates: their `splash_screen.dart` pushes
/// `AuthenticatedPlaceholderScreen` on `Authenticated` state, and that
/// screen's own doc comment says "Dashboard and onboarding modules
/// will integrate here." The merge step is swapping that widget for
/// this one — no other wiring needed, since `ProfileProvider.load()`
/// reads identity from the live Supabase session itself (see
/// `AppSupabase.currentUserId`), which is confirmed to be the exact
/// same session Authentication's own `AuthRepository` uses.
class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key});

  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    // Identity is not passed in here — ProfileProvider.load() reads
    // AppSupabase.currentUserId (the live session) itself, so there's
    // nothing to thread through and no risk of it going stale.
    // Authentication's flow just needs to land the user here after a
    // real sign-in has populated that session.
    await context.read<ProfileProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          context.read<ProfileProvider>().clear();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          if (provider.loadState == ProfileLoadState.loading ||
              provider.loadState == ProfileLoadState.initial) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (provider.loadState == ProfileLoadState.notSignedIn) {
            return _MessageScreen(
              message: provider.errorMessage ?? 'You need to be signed in to continue.',
            );
          }
          if (provider.loadState == ProfileLoadState.error) {
            return _MessageScreen(
              message: provider.errorMessage ?? 'Something went wrong loading your profile.',
              onRetry: _loadProfile,
            );
          }
          if (provider.hasGuidedSetupMinimum) {
            return const ProfileViewScreen();
          }
          return const GuidedSetupScreen();
        },
      ),
    );
  }
}

/// Simple full-screen message state for "not signed in" / load errors
/// — Authentication owns the real sign-in screen; this is just a
/// placeholder so ProfileGate has somewhere sane to land instead of
/// silently showing Guided Setup for a session that doesn't exist.
class _MessageScreen extends StatelessWidget {
  const _MessageScreen({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
