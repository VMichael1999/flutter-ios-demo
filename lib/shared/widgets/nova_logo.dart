import 'package:flutter/material.dart';

class NovaLogo extends StatelessWidget {
  const NovaLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.35),
            blurRadius: size / 3,
          ),
        ],
      ),
      child: Icon(Icons.auto_awesome, color: scheme.onPrimary, size: size * 0.5),
    );
  }
}
