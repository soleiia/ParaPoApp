import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:para_po/core/theme/app_theme.dart';

// ── Philippine Sun Painter ────────────────────────────────────────────────────
class SunPainter extends CustomPainter {
  final Color color;
  const SunPainter({this.color = AppColors.yellow});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final cx = size.width * 0.3;
    final cy = size.height * 0.85;
    final r = size.width * 0.38;
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2 / 8) - math.pi / 2;
      const halfW = 0.07;
      final tip = Offset(
          cx + math.cos(angle) * r * 1.6, cy + math.sin(angle) * r * 1.6);
      final left = Offset(cx + math.cos(angle - halfW) * r * 0.55,
          cy + math.sin(angle - halfW) * r * 0.55);
      final right = Offset(cx + math.cos(angle + halfW) * r * 0.55,
          cy + math.sin(angle + halfW) * r * 0.55);
      final path = Path()
        ..moveTo(left.dx, left.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(right.dx, right.dy)
        ..close();
      canvas.drawPath(path, paint);
    }
    canvas.drawCircle(Offset(cx, cy), r * 0.5, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Page Header ───────────────────────────────────────────────────────────────
class PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;
  final ValueChanged<String> onSearch;
  final List<Widget> extraActions;

  const PageHeader({
    super.key,
    required this.title,
    required this.onAdd,
    required this.onSearch,
    this.extraActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.blueDark, AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      )),
                ),
                ...extraActions,
                const SizedBox(width: 8),
                CircleIconBtn(icon: Icons.add, onTap: onAdd),
              ]),
              const SizedBox(height: 14),
              _SearchBox(onChanged: onSearch),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Circle icon button ────────────────────────────────────────────────────────
class CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const CircleIconBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.28),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      );
}

// ── Search box ────────────────────────────────────────────────────────────────
class _SearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBox({required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Search',
            hintStyle: TextStyle(color: Colors.white60),
            prefixIcon: Icon(Icons.search, color: Colors.white70, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
}

// ── Yellow action button ──────────────────────────────────────────────────────
class YellowBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  const YellowBtn(
      {super.key, required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.yellow,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.textDark, size: 16),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Blue primary button ───────────────────────────────────────────────────────
class BlueBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const BlueBtn({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.5,
                )),
          ),
        ),
      );
}

// ── Detail row ────────────────────────────────────────────────────────────────
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const DetailRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: const TextStyle(color: AppColors.textMid, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ]),
      );
}

// ── Sheet drag handle ─────────────────────────────────────────────────────────
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});
  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Center(
            child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(height: 8),
      ]);
}

// ── Status badge ──────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final bool active;
  const StatusBadge({super.key, required this.active});
  @override
  Widget build(BuildContext context) => Text(
        active ? 'TRUE' : 'FALSE',
        style: TextStyle(
          color: active ? AppColors.blue : AppColors.red,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String message;
  const EmptyState({super.key, this.message = 'No results'});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.inbox_outlined,
              size: 56, color: AppColors.lightGrey),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: AppColors.textLight, fontSize: 15)),
        ]),
      );
}

// ── Loading state ─────────────────────────────────────────────────────────────
class LoadingState extends StatelessWidget {
  const LoadingState({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.blue));
}

// ── Delete confirm dialog ─────────────────────────────────────────────────────
Future<bool?> showDeleteDialog(BuildContext context, String name) =>
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Item',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

// ── Shared dialog text field ──────────────────────────────────────────────────
Widget buildDialogField(
  TextEditingController ctrl,
  String hint, {
  TextInputType? type,
}) =>
    TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textLight),
        filled: true,
        fillColor: AppColors.offWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
