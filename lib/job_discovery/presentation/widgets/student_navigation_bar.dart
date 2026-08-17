import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/route_names.dart';
import 'internloom_brand.dart';

/// Persistent navigation for the top-level student sections.
class StudentNavigationBar extends StatelessWidget {
  const StudentNavigationBar({required this.selectedIndex, super.key});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: InternloomColors.white,
      indicatorColor: InternloomColors.greenLight,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        if (index == selectedIndex) return;
        final direction = index < selectedIndex ? 'back' : 'forward';
        switch (index) {
          case 0:
            context.goNamed(
              RouteNames.studentDiscover,
              queryParameters: {'tabDirection': direction},
            );
            return;
          case 1:
            context.goNamed(
              RouteNames.studentSavedJobs,
              queryParameters: {'tabDirection': direction},
            );
            return;
          case 2:
            context.goNamed(
              RouteNames.studentApplications,
              queryParameters: {'tabDirection': direction},
            );
            return;
          case 3:
            context.goNamed(
              RouteNames.studentProfile,
              queryParameters: {'tabDirection': direction},
            );
            return;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Discover'),
        NavigationDestination(icon: Icon(Icons.bookmark_border), selectedIcon: Icon(Icons.bookmark), label: 'Saved'),
        NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Applications'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
