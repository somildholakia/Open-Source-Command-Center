import 'package:flutter/material.dart';

/// Responsive, cartoon-inspired section banner shared by the app's feature
/// screens. Uses native Flutter shapes instead of remote illustrations.
class CartoonPageBanner extends StatelessWidget {
  const CartoonPageBanner({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: dark ? 0.16 : 0.09),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: dark ? 0.08 : 0.06),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: scheme.onSurface.withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 29),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.45,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant, height: 1.25),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.auto_awesome_rounded, color: accent, size: 20),
        ],
      ),
    );
  }
}
