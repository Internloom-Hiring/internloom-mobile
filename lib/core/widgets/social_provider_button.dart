import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Which external identity provider a [SocialProviderButton] represents.
enum SocialAuthProvider { google, linkedIn }

/// A branded "Continue with X" button for external OAuth providers
/// (currently Google and LinkedIn). Shows a small provider logo, label,
/// and swaps to a spinner while [isAuthenticating] is true.
class SocialProviderButton extends StatelessWidget {
  final SocialAuthProvider provider;
  final VoidCallback? onPressed;
  final bool isAuthenticating;

  const SocialProviderButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isAuthenticating = false,
  });

  String get _buttonLabel {
    switch (provider) {
      case SocialAuthProvider.google:
        return 'Continue with Google';
      case SocialAuthProvider.linkedIn:
        return 'Continue with LinkedIn';
    }
  }

  Widget get _providerLogo {
    switch (provider) {
      case SocialAuthProvider.google:
        return Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
          height: 20,
          width: 20,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.g_mobiledata, color: AppColors.ink, size: 24),
        );
      case SocialAuthProvider.linkedIn:
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFF0A66C2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'in',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              height: 1,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isAuthenticating ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.border, width: 1.5),
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: isAuthenticating
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _providerLogo,
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    _buttonLabel,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
