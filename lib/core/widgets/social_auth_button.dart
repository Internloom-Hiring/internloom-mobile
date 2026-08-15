import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum SocialType { google, linkedin }

/// Branded social authentication button (Google & LinkedIn)
class SocialAuthButton extends StatelessWidget {
  final SocialType type;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialAuthButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.isLoading = false,
  });

  String get _label {
    switch (type) {
      case SocialType.google:
        return 'Continue with Google';
      case SocialType.linkedin:
        return 'Continue with LinkedIn';
    }
  }

  Widget get _logo {
    switch (type) {
      case SocialType.google:
        return Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
          height: 20,
          width: 20,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.g_mobiledata, color: AppColors.ink, size: 24),
        );
      case SocialType.linkedin:
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
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.border, width: 1.5),
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: isLoading
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
                _logo,
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    _label,
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
