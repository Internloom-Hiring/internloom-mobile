import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Leaf Green Primary CTA button with loading state
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonContent = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.white),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.leafGreen,
          disabledBackgroundColor: AppColors.leafGreen.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: buttonContent,
      ),
    );
  }
}
