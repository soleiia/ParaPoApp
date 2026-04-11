import 'package:flutter/material.dart';
import 'package:para_po/core/theme/app_theme.dart';
import 'package:para_po/core/app_state.dart';
import 'package:para_po/shared/widgets/widgets.dart';
import 'package:para_po/features/map/map_page.dart';
import 'package:para_po/features/transportation/transportation_page.dart';
import 'package:para_po/features/routes/routes_page.dart';
import 'package:para_po/features/terminals/terminals_page.dart';
import 'package:para_po/features/zones/zones_page.dart';
import 'package:para_po/features/admin/admin_page.dart';

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

const _navItems = [
  _NavItem(Icons.map_outlined,            'Map'),
  _NavItem(Icons.directions_bus_outlined, 'Transportation'),
  _NavItem(Icons.route_outlined,          'Routes'),
  _NavItem(Icons.place_outlined,          'Terminals'),
  _NavItem(Icons.grid_view_outlined,      'Zones'),
  _NavItem(Icons.admin_panel_settings,    'Admin'),
];

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late AnimationController _ctrl;
  late Animation<double> _widthAnim;
  late Animation<double> _fadeAnim;

  static const double _kExpanded  = 210.0;
  static const double _kCollapsed =  64.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _widthAnim = Tween<double>(begin: _kCollapsed, end: _kExpanded)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic));
    _fadeAnim  = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0)));
    _ctrl.value = 1.0;
    AppState.instance.addListener(_onStateChange);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onStateChange);
    _ctrl.dispose();
    super.dispose();
  }

  void _onStateChange() => setState(() {});

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  Widget _page() {
    switch (AppState.instance.tabIndex) {
      case 0: return const MapPage();
      case 1: return const TransportationPage();
      case 2: return const RoutesPage();
      case 3: return const TerminalsPage();
      case 4: return const ZonesPage();
      case 5: return const AdminPage();
      default: return const MapPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Row(children: [
        AnimatedBuilder(
          animation: _widthAnim,
          builder: (_, __) => _SideNav(
            width: _widthAnim.value, fadeValue: _fadeAnim.value,
            expanded: _expanded, selectedIndex: AppState.instance.tabIndex,
            onToggle: _toggle,
            onSelect: (i) => AppState.instance.setTab(i),
          ),
        ),
        Expanded(child: _page()),
      ]),
    );
  }
}

class _SideNav extends StatelessWidget {
  final double width, fadeValue;
  final bool expanded;
  final int selectedIndex;
  final VoidCallback onToggle;
  final ValueChanged<int> onSelect;

  const _SideNav({required this.width, required this.fadeValue, required this.expanded,
      required this.selectedIndex, required this.onToggle, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: Stack(children: [
      Positioned.fill(child: Container(decoration: const BoxDecoration(
        color: AppColors.blue,
        boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(4, 0))],
      ))),
      Positioned(bottom: -30, left: -20,
        child: SizedBox(width: width * 1.3, height: width * 1.3,
            child: const CustomPaint(painter: SunPainter()))),
      SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        // Hamburger
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: GestureDetector(onTap: onToggle,
            child: SizedBox(width: 36, height: 36,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (_) =>
                Container(margin: const EdgeInsets.symmetric(vertical: 2.5), height: 2, width: 22,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))))))),
        ),
        // Logo
        if (expanded && fadeValue > 0.1)
          Opacity(opacity: fadeValue,
            child: Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(children: [
                Container(width: 34, height: 34,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: Text('🚌', style: TextStyle(fontSize: 18)))),
                const SizedBox(width: 10),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Para Po', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('Cabuyao Transit', style: TextStyle(color: Colors.white60, fontSize: 10)),
                ]),
              ]))),
        const SizedBox(height: 16),
        // Nav items
        Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: _navItems.length,
          itemBuilder: (_, i) {
            final item   = _navItems[i];
            final active = selectedIndex == i;
            // Admin item has a visual separator before it
            final isAdmin = i == 5;
            return Column(children: [
              if (isAdmin) Container(margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  height: 1, color: Colors.white.withValues(alpha: 0.2)),
              GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: active ? Colors.white.withValues(alpha: 0.22) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: active ? Border.all(color: Colors.white.withValues(alpha: 0.4)) : null,
                  ),
                  child: Row(mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min, children: [
                    Icon(item.icon, color: isAdmin ? const Color(0xFFFFD54F) : Colors.white, size: 22),
                    if (expanded && fadeValue > 0.2) ...[
                      const SizedBox(width: 12),
                      Flexible(child: Opacity(opacity: fadeValue,
                        child: Text(item.label, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: 14,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w400)))),
                    ],
                  ]),
                ),
              ),
            ]);
          })),
        // Settings
        Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
          child: GestureDetector(
            onTap: () => _showSettings(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 10, vertical: 12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min, children: [
                const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
                if (expanded && fadeValue > 0.2) ...[
                  const SizedBox(width: 12),
                  Opacity(opacity: fadeValue,
                    child: const Text('Settings', style: TextStyle(color: Colors.white70, fontSize: 13))),
                ],
              ]),
            ),
          )),
      ])),
    ]));
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SheetHandle(),
          const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 16),
          // Fare mode
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Discount Mode', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 15)),
                const Text('Students, Seniors, PWD (20% off)', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
              ]),
              ListenableBuilder(listenable: AppState.instance, builder: (_, __) =>
                Switch(value: AppState.instance.isDiscounted,
                  activeThumbColor: AppColors.blue, onChanged: (_) => AppState.instance.toggleDiscount())),
            ])),
          const SizedBox(height: 12),
          ...[
            ('Notifications', Icons.notifications_outlined),
            ('Language',      Icons.language_outlined),
            ('About Para Po', Icons.info_outline),
          ].map((e) => ListTile(contentPadding: EdgeInsets.zero,
            leading: Container(width: 38, height: 38,
              decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(e.$2, color: AppColors.blue, size: 20)),
            title: Text(e.$1, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
            onTap: () => Navigator.pop(context))),
        ]),
      ));
  }
}
