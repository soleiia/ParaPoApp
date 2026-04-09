import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:para_po/providers/fare_provider.dart';

/// Displays a fare amount, automatically applying discount from [FareProvider].
/// Shows original fare as strikethrough when discounted.
class FareBadge extends StatelessWidget {
  final double baseFare;
  final bool large;

  const FareBadge({super.key, required this.baseFare, this.large = false});

  @override
  Widget build(BuildContext context) {
    final fareProvider = context.watch<FareProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDiscounted = fareProvider.isDiscounted;
    final computedFare = fareProvider.computeFare(baseFare);
    final rounded = computedFare.ceilToDouble();

    final mainStyle = large
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDiscounted ? colorScheme.tertiary : colorScheme.primary,
            )
        : Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDiscounted ? colorScheme.tertiary : colorScheme.primary,
            );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isDiscounted) ...[
          Text(
            '₱${baseFare.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          '₱${rounded.toStringAsFixed(0)}',
          style: mainStyle,
        ),
        if (isDiscounted) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '-20%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
