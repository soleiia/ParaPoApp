import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:para_po/providers/fare_provider.dart';

class PassengerTypeSelector extends StatelessWidget {
  /// Set [compact] to true for the map bottom sheet (smaller, horizontal pill).
  final bool compact;

  const PassengerTypeSelector({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final fareProvider = context.watch<FareProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (compact) {
      return _buildCompactToggle(context, fareProvider, colorScheme);
    }
    return _buildFullSelector(context, fareProvider, colorScheme);
  }

  Widget _buildCompactToggle(
    BuildContext context,
    FareProvider fareProvider,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CompactChip(
            label: 'Regular',
            icon: Icons.person_outline,
            selected: !fareProvider.isDiscounted,
            onTap: () => fareProvider.setPassengerType(PassengerType.regular),
          ),
          _CompactChip(
            label: 'Discounted',
            icon: Icons.discount_outlined,
            selected: fareProvider.isDiscounted,
            selectedColor: colorScheme.tertiary,
            onTap: () =>
                fareProvider.setPassengerType(PassengerType.discounted),
          ),
        ],
      ),
    );
  }

  Widget _buildFullSelector(
    BuildContext context,
    FareProvider fareProvider,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.confirmation_number_outlined,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Passenger type',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FullTypeCard(
                    label: 'Regular',
                    description: 'Standard fare',
                    icon: Icons.person,
                    selected: !fareProvider.isDiscounted,
                    selectedColor: colorScheme.primaryContainer,
                    selectedBorderColor: colorScheme.primary,
                    onTap: () =>
                        fareProvider.setPassengerType(PassengerType.regular),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FullTypeCard(
                    label: 'Discounted',
                    description: '20% off (Student / Senior / PWD)',
                    icon: Icons.discount,
                    selected: fareProvider.isDiscounted,
                    selectedColor: colorScheme.tertiaryContainer,
                    selectedBorderColor: colorScheme.tertiary,
                    onTap: () =>
                        fareProvider.setPassengerType(PassengerType.discounted),
                  ),
                ),
              ],
            ),
            if (fareProvider.isDiscounted) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withAlpha(128),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Per LTFRB rules, show a valid ID '
                        '(school ID, senior citizen card, or PWD card) '
                        'to the driver.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onTertiaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color? selectedColor;
  final VoidCallback onTap;

  const _CompactChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = selectedColor ?? colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullTypeCard extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final Color selectedBorderColor;
  final VoidCallback onTap;

  const _FullTypeCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.selectedBorderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? selectedColor : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? selectedBorderColor : colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? selectedBorderColor
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? selectedBorderColor
                            : colorScheme.onSurface,
                      ),
                ),
                if (selected) ...[
                  const Spacer(),
                  Icon(Icons.check_circle,
                      size: 16, color: selectedBorderColor),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
