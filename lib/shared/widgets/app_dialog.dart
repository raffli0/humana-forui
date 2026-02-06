import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppDialog {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String primaryButtonText = "Okay",
    VoidCallback? onPrimary,
    String? secondaryButtonText,
    VoidCallback? onSecondary,
    bool isDestructive = false,
  }) {
    final colors = context.colors;
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: colors.surface,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              if (secondaryButtonText != null) ...[
                _buildButton(
                  context: context,
                  text: secondaryButtonText,
                  onTap: () {
                    Navigator.pop(context);
                    onSecondary?.call();
                  },
                  isPrimary: false,
                ),
                const SizedBox(height: 12),
              ],
              _buildButton(
                context: context,
                text: primaryButtonText,
                onTap: () {
                  Navigator.pop(context);
                  onPrimary?.call();
                },
                isPrimary: true,
                isDestructive: isDestructive,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildButton({
    required BuildContext context,
    required String text,
    required VoidCallback onTap,
    required bool isPrimary,
    bool isDestructive = false,
  }) {
    final colors = context.colors;
    final bgColor = isPrimary
        ? (isDestructive ? Colors.red.shade50 : colors.accent)
        : Colors.transparent;
    final textColor = isPrimary
        ? (isDestructive ? Colors.red : Colors.white)
        : colors.textSecondary;

    if (!isPrimary) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: bgColor,
          boxShadow: isPrimary && !isDestructive
              ? [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: textColor,
          ),
        ),
      ),
    );
  }

  /// Preset: Success
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      primaryButtonText: "Okay",
    );
  }

  /// Preset: Error
  static Future<void> showError({
    required BuildContext context,
    String title = "Action not available",
    String message = "Please complete the previous step first.",
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      primaryButtonText: "Okay",
      // Could use simple alert style or sticking to the custom one
    );
  }
}
