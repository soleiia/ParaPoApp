import 'package:flutter/material.dart';
import 'package:para_po/core/theme/app_theme.dart';
import 'package:para_po/shared/widgets/widgets.dart';
import 'package:para_po/features/map/map_page.dart';
import 'package:para_po/features/transportation/transportation_page.dart';
import 'package:para_po/features/routes/routes_page.dart';
import 'package:para_po/features/terminals/terminals_page.dart';
import 'package:para_po/features/zones/zones_page.dart';

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

const _navItems = [
  _NavItem(Icons.map_outlined, 'Map'),
  _NavItem(Icons.directions_bus_outlined, 'Transportation'),
  _NavItem(Icons.route_outlined, 'Routes'),
  _NavItem(Icons.place_outlined, 'Terminals'),
  _NavItem(Icons.grid_view_outlined, 'Zones'),
];

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _expanded = true;
  late AnimationController _ctrl;
  late Animation<double> _widthAnim;
  late Animation<double> _fadeAnim;

  static const double _kExpanded = 210.0;
  static const double _kCollapsed = 64.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _widthAnim = Tween<double>(begin: _kCollapsed, end: _kExpanded)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0)));
    _ctrl.value = 1.0;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  Widget _page() {
    switch (_selectedIndex) {
      case 0:
        return const MapPage();
      case 1:
        return const TransportationPage();
      case 2:
        return const RoutesScreen();
      case 3:
        return const TerminalsPage();
      case 4:
        return const ZonesPage();
      default:
        return const MapPage();
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
            width: _widthAnim.value,
            fadeValue: _fadeAnim.value,
            expanded: _expanded,
            selectedIndex: _selectedIndex,
            onToggle: _toggle,
            onSelect: (i) => setState(() => _selectedIndex = i),
          ),
        ),
        Expanded(child: _page()),
      ]),
    );
  }
}

class _SideNav extends StatelessWidget {
  final double width;
  final double fadeValue;
  final bool expanded;
  final int selectedIndex;
  final VoidCallback onToggle;
  final ValueChanged<int> onSelect;

  const _SideNav({
    required this.width,
    required this.fadeValue,
    required this.expanded,
    required this.selectedIndex,
    required this.onToggle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(children: [
        Positioned.fill(
            child: Container(
          decoration: const BoxDecoration(
            color: AppColors.blue,
            boxShadow: [
              BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 16,
                  offset: Offset(4, 0))
            ],
          ),
        )),
        Positioned(
            bottom: -30,
            left: -20,
            child: SizedBox(
                width: width * 1.3,
                height: width * 1.3,
                child: const CustomPaint(painter: SunPainter()))),
        SafeArea(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          // Hamburger
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: GestureDetector(
              onTap: onToggle,
              child: SizedBox(
                width: 36,
                height: 36,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        3,
                        (_) => Container(
                              margin: const EdgeInsets.symmetric(vertical: 2.5),
                              height: 2,
                              width: 22,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2)),
                            ))),
              ),
            ),
          ),
          // Logo + name
          if (expanded && fadeValue > 0.1)
            Opacity(
                opacity: fadeValue,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  child: Row(children: [
                    Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Center(
                            child: Text('🚌', style: TextStyle(fontSize: 18)))),
                    const SizedBox(width: 10),
                    const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Para Po',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                          Text('Transit Guide',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 10)),
                        ]),
                  ]),
                )),
          const SizedBox(height: 20),
          // Nav items
          Expanded(
              child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _navItems.length,
            itemBuilder: (_, i) {
              final item = _navItems[i];
              final active = selectedIndex == i;
              return GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: EdgeInsets.symmetric(
                      horizontal: expanded ? 14 : 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withValues(alpha: 0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: active
                        ? Border.all(color: Colors.white.withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Row(
                    mainAxisSize:
                        expanded ? MainAxisSize.max : MainAxisSize.min,
                    children: [
                      Icon(item.icon, color: Colors.white, size: 22),
                      if (expanded && fadeValue > 0.2) ...[
                        const SizedBox(width: 12),
                        Flexible(
                            child: Opacity(
                                opacity: fadeValue,
                                child: Text(item.label,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: active
                                            ? FontWeight.w700
                                            : FontWeight.w400)))),
                      ],
                    ],
                  ),
                ),
              );
            },
          )),
          // Settings
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
            child: GestureDetector(
              onTap: () => _showSettings(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: expanded ? 14 : 10, vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                    mainAxisSize:
                        expanded ? MainAxisSize.max : MainAxisSize.min,
                    children: [
                      const Icon(Icons.settings_outlined,
                          color: Colors.white70, size: 20),
                      if (expanded && fadeValue > 0.2) ...[
                        const SizedBox(width: 12),
                        Opacity(
                            opacity: fadeValue,
                            child: const Text('Settings',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13))),
                      ],
                    ]),
              ),
            ),
          ),
        ])),
      ]),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const Text('Settings',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 16),
              ...[
                ('Notifications', Icons.notifications_outlined),
                ('Language', Icons.language_outlined),
                ('About Para Po', Icons.info_outline),
              ].map((e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            color: AppColors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(e.$2, color: AppColors.blue, size: 20)),
                    title: Text(e.$1,
                        style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textLight),
                    onTap: () => Navigator.pop(context),
                  )),
            ]),
      ),
    );
  }
}
