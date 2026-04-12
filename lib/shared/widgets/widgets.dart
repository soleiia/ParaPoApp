import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:para_po/core/theme/app_theme.dart';
import 'package:para_po/core/app_state.dart';

class SunPainter extends CustomPainter {
  final Color color;
  const SunPainter({this.color = AppColors.yellow});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final cx = size.width * 0.3, cy = size.height * 0.85, r = size.width * 0.38;
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2 / 8) - math.pi / 2;
      const hw = 0.07;
      final tip   = Offset(cx + math.cos(angle) * r * 1.6,  cy + math.sin(angle) * r * 1.6);
      final left  = Offset(cx + math.cos(angle - hw) * r * 0.55, cy + math.sin(angle - hw) * r * 0.55);
      final right = Offset(cx + math.cos(angle + hw) * r * 0.55, cy + math.sin(angle + hw) * r * 0.55);
      canvas.drawPath(Path()..moveTo(left.dx, left.dy)..lineTo(tip.dx, tip.dy)..lineTo(right.dx, right.dy)..close(), paint);
    }
    canvas.drawCircle(Offset(cx, cy), r * 0.5, paint);
  }
  @override bool shouldRepaint(_) => false;
}

class PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;
  final ValueChanged<String> onSearch;
  final List<Widget> extraActions;
  const PageHeader({super.key, required this.title, required this.onAdd,
      required this.onSearch, this.extraActions = const []});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.blueDark, AppColors.blue],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: SafeArea(bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white,
                  fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5))),
              ...extraActions,
              const SizedBox(width: 8),
              CircleIconBtn(icon: Icons.add, onTap: onAdd),
            ]),
            const SizedBox(height: 14),
            _SearchBox(onChanged: onSearch),
          ]),
        ),
      ),
    );
  }
}

// ── Compact inline fare toggle (used in page headers and map bar) ─────────────
class FareToggle extends StatelessWidget {
  const FareToggle({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (_, __) {
        final disc = AppState.instance.isDiscounted;
        return GestureDetector(
          onTap: AppState.instance.toggleDiscount,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: disc ? AppColors.yellow : Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: disc
                      ? AppColors.yellowDark
                      : Colors.white.withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(disc ? Icons.percent : Icons.attach_money,
                  color: disc ? AppColors.textDark : Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(disc ? 'Discounted' : 'Regular',
                  style: TextStyle(
                      color: disc ? AppColors.textDark : Colors.white,
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        );
      },
    );
  }
}

// ── Card-style passenger type selector (used inside route/transport list pages) ─
/// Displays two side-by-side cards: Regular | Discounted.
/// Matches the UI in the Routes & Fares screen mockup.
class PassengerTypeSelector extends StatelessWidget {
  const PassengerTypeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (_, __) {
        final disc = AppState.instance.isDiscounted;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Label row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              const Icon(Icons.people_outline,
                  color: AppColors.textMid, size: 16),
              const SizedBox(width: 6),
              const Text('Passenger type', style: TextStyle(
                  color: AppColors.textMid, fontSize: 13,
                  fontWeight: FontWeight.w600)),
            ]),
          ),
          // Card row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              // Regular card
              Expanded(child: GestureDetector(
                onTap: disc ? AppState.instance.toggleDiscount : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: !disc ? AppColors.blue : AppColors.offWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: !disc ? AppColors.blue : AppColors.lightGrey,
                        width: 1.5),
                    boxShadow: !disc
                        ? [BoxShadow(
                            color: AppColors.blue.withValues(alpha: 0.18),
                            blurRadius: 8, offset: const Offset(0, 3))]
                        : null,
                  ),
                  child: Row(children: [
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Regular', style: TextStyle(
                          color: !disc ? Colors.white : AppColors.textMid,
                          fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Standard fare', style: TextStyle(
                          color: !disc
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppColors.textLight,
                          fontSize: 11)),
                    ])),
                    if (!disc)
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 14)),
                  ]),
                ),
              )),
              const SizedBox(width: 10),
              // Discounted card
              Expanded(child: GestureDetector(
                onTap: !disc ? AppState.instance.toggleDiscount : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: disc ? AppColors.yellow : AppColors.offWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: disc
                            ? AppColors.yellowDark
                            : AppColors.lightGrey,
                        width: 1.5),
                    boxShadow: disc
                        ? [BoxShadow(
                            color: AppColors.yellow.withValues(alpha: 0.3),
                            blurRadius: 8, offset: const Offset(0, 3))]
                        : null,
                  ),
                  child: Row(children: [
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Discounted', style: TextStyle(
                          color: disc
                              ? AppColors.textDark
                              : AppColors.textMid,
                          fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('20% off (Student /\nSenior / PWD)',
                          style: TextStyle(
                              color: disc
                                  ? AppColors.textDark.withValues(alpha: 0.65)
                                  : AppColors.textLight,
                              fontSize: 11)),
                    ])),
                    if (disc)
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.textDark.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_offer,
                            color: AppColors.textDark, size: 13)),
                    if (!disc)
                      Icon(Icons.local_offer,
                          color: AppColors.textLight, size: 16),
                  ]),
                ),
              )),
            ]),
          ),
          const Divider(color: AppColors.divider, height: 1),
        ]);
      },
    );
  }
}

class FareDisplay extends StatelessWidget {
  final double fare;
  final bool compact;
  const FareDisplay({super.key, required this.fare, this.compact = false});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (_, __) {
        final disc = AppState.instance.isDiscounted;
        final display = disc ? fare * 0.80 : fare;
        if (compact) {
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Text('₱${display.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.blue, fontSize: 11, fontWeight: FontWeight.w800)),
            if (disc) ...[
              const SizedBox(width: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(4)),
                child: const Text('20% OFF', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.textDark))),
            ],
          ]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('₱${display.toStringAsFixed(2)}',
              style: TextStyle(color: disc ? const Color(0xFF2E7D32) : AppColors.textMid,
                  fontSize: 13, fontWeight: FontWeight.w700)),
          if (disc)
            Text('Regular: ₱${fare.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.textLight, fontSize: 11,
                    decoration: TextDecoration.lineThrough)),
        ]);
      },
    );
  }
}

class CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const CircleIconBtn({super.key, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 36, height: 36,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.28), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22)),
  );
}

class _SearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBox({required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    height: 42,
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(14)),
    child: TextField(
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: const InputDecoration(hintText: 'Search', hintStyle: TextStyle(color: Colors.white60),
          prefixIcon: Icon(Icons.search, color: Colors.white70, size: 20),
          border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12)),
    ),
  );
}

class YellowBtn extends StatelessWidget {
  final String label; final VoidCallback onTap; final IconData? icon;
  const YellowBtn({super.key, required this.label, required this.onTap, this.icon});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(30)),
      child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null) ...[Icon(icon, color: AppColors.textDark, size: 16), const SizedBox(width: 6)],
        Flexible(child: Text(label, style: const TextStyle(color: AppColors.textDark,
            fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis)),
      ]),
    ),
  );
}

class BlueBtn extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const BlueBtn({super.key, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(30)),
      child: Center(child: Text(label, style: const TextStyle(color: Colors.white,
          fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5))),
    ),
  );
}

class DetailRow extends StatelessWidget {
  final String label, value;
  const DetailRow(this.label, this.value, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppColors.textMid, fontSize: 14)),
      Text(value,  style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w700)),
    ]),
  );
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    const SizedBox(height: 12),
    Center(child: Container(width: 40, height: 4,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
    const SizedBox(height: 8),
  ]);
}

class StatusBadge extends StatelessWidget {
  final bool active;
  const StatusBadge({super.key, required this.active});
  @override
  Widget build(BuildContext context) => Text(active ? 'TRUE' : 'FALSE',
    style: TextStyle(color: active ? AppColors.blue : AppColors.red,
        fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5));
}

class EmptyState extends StatelessWidget {
  final String message;
  const EmptyState({super.key, this.message = 'No results'});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.inbox_outlined, size: 56, color: AppColors.lightGrey),
    const SizedBox(height: 12),
    Text(message, style: const TextStyle(color: AppColors.textLight, fontSize: 15)),
  ]));
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.blue));
}

Future<bool?> showDeleteDialog(BuildContext context, String name) =>
    showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Delete Item', style: TextStyle(fontWeight: FontWeight.w800)),
      content: Text('Are you sure you want to delete "$name"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700))),
      ],
    ));

Widget buildDialogField(TextEditingController ctrl, String hint, {TextInputType? type}) =>
    TextField(controller: ctrl, keyboardType: type,
      decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textLight),
        filled: true, fillColor: AppColors.offWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
    );
