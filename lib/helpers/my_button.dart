import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  /// Show a loading spinner and disable taps while true
  final bool isLoading;

  /// Optionally disable the button (independent of loading)
  final bool isEnabled;

  const MyButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    // Only clickable when enabled, not loading, and onTap is provided
    final bool isInteractive = isEnabled && !isLoading && onTap != null;

    final Color bgColor = theme.primary.withOpacity(isInteractive ? 1.0 : 0.6);
    final Color fgColor = theme.inversePrimary;

    return Opacity(
      opacity: isInteractive ? 1.0 : 0.95,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isInteractive ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: isLoading
                  ? SizedBox(
                      key: const ValueKey('spinner'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                      ),
                    )
                  : Text(
                      text,
                      key: const ValueKey('text'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: fgColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
