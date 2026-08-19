import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';

/// Branded splash/loading widget with Internloom logo placeholder
class BrandedLoading extends StatelessWidget {
  final String? text;

  const BrandedLoading({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/internloom_logo.svg',
              width: 96,
              height: 96,
            ),
            const SizedBox(height: 24),
            Text(
              'Internloom',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Student Portal',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.leafGreen),
              ),
            ),
            if (text != null) ...[
              const SizedBox(height: 16),
              Text(
                text!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
