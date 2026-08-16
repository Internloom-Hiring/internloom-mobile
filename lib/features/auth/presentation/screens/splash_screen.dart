import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/branded_loading.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';

/// Branded splash screen — fires [AppStarted] to trigger the initial
/// session check then shows the branded loader.
///
/// All navigation away from this screen is handled declaratively by
/// AppRouter's redirect callback (which subscribes to AuthBloc via
/// [_RouterRefreshListenable]). There is no BlocListener here because
/// adding one would create a race between the listener's imperative
/// [context.goNamed] call and the router's declarative redirect —
/// whichever fires second would try to navigate on a context that may
/// already be detached from the navigator.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AppStarted());
  }

  @override
  Widget build(BuildContext context) {
    return const BrandedLoading(text: 'Loading authentication session...');
  }
}
