import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:para_po/core/theme/app_theme.dart';
import 'package:para_po/core/app_state.dart';
import 'package:para_po/core/models/models.dart';
import 'package:para_po/core/services/directions_service.dart';
import 'package:para_po/core/repositories/repositories.dart';
import 'package:para_po/shared/widgets/widgets.dart';
import 'map_widget.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _fromCtrl  = TextEditingController();
  final _toCtrl    = TextEditingController();
  final _routeRepo = RouteRepository();

  bool _showSheet  = false;
  bool _loading    = false;
  DirectionsResult? _directions;
  AppLatLng? _originPin;
  AppLatLng? _destPin;
  String _errorMsg  = '';
  bool _isSatellite = false;

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onStateChange);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkPendingRoute());
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onStateChange);
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (AppState.instance.pendingRoute != null) {
      _checkPendingRoute();
    }
  }

  void _checkPendingRoute() {
    final route = AppState.instance.pendingRoute;
    if (route == null) return;
    AppState.instance.clearPendingRoute();
    setState(() {
      _fromCtrl.text = route.origin;
      _toCtrl.text   = route.destination;
      _originPin     = route.originLatLng;
      _destPin       = route.destLatLng;
    });
    _startNavigation();
  }

  Future<void> _startNavigation() async {
    if (_fromCtrl.text.trim().isEmpty || _toCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter both Point A and Point B'),
          backgroundColor: AppColors.blue));
      return;
    }

    setState(() { _loading = true; _errorMsg = ''; });

    AppLatLng? origin = _originPin;
    AppLatLng? dest   = _destPin;

    // If no coordinates set, look them up from the database
    if (origin == null || dest == null) {
      final routes = await _routeRepo.search(_fromCtrl.text.trim());
      final match  = routes.where((r) => r.destination
          .toLowerCase()
          .contains(_toCtrl.text.trim().toLowerCase()))
          .firstOrNull;
      if (match != null) {
        origin = match.originLatLng;
        dest   = match.destLatLng;
        setState(() { _originPin = origin; _destPin = dest; });
      }
    }

    DirectionsResult? result;
    if (origin != null && dest != null) {
      result = await DirectionsService.getDirections(
          origin: origin, destination: dest);
    }

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _loading  = false;
        _errorMsg = 'Could not get directions. Check internet connection.';
      });
      return;
    }

    setState(() {
      _directions = result;
      _originPin  = result!.origin;
      _destPin    = result!.destination;
      _showSheet  = true;
      _loading    = false;
    });
  }

  void _clearRoute() {
    setState(() {
      _showSheet  = false;
      _directions = null;
      _originPin  = null;
      _destPin    = null;
      _errorMsg   = '';
    });
    _fromCtrl.clear();
    _toCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Column(children: [
        // ── Top bar ─────────────────────────────────────────────────────────
        Container(
          color: AppColors.blue,
          child: SafeArea(bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                const Text('Cabuyao', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800,
                    fontSize: 22)),
                const Spacer(),
                // Satellite / Street toggle
                GestureDetector(
                  onTap: () {
                    setState(() => _isSatellite = !_isSatellite);
                    MapWidget.toggleMapType();
                  },
                  child: Container(
                    width: 36, height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                        color: _isSatellite
                            ? AppColors.yellow
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(
                        _isSatellite ? Icons.map : Icons.satellite_alt,
                        color: _isSatellite
                            ? AppColors.textDark
                            : Colors.white,
                        size: 20)),
                ),
                // Fare toggle
                const FareToggle(),
              ]),
            )),
        ),

        // ── Map ─────────────────────────────────────────────────────────────
        Expanded(child: Stack(children: [
          // Unified flutter_map (works on all platforms)
          Positioned.fill(child: MapWidget(
            directionsPolyline: _directions?.polylinePoints,
            originPin: _originPin,
            destPin:   _destPin,
            showRoute: _showSheet,
          )),

          // Input card
          Positioned(top: 16, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16, offset: const Offset(0, 4))]),
              child: Column(children: [
                _pointRow(_fromCtrl, 'INPUT POINT A (e.g. Cabuyao Rotunda)',
                    AppColors.blue, null,
                    onTap: () => _showSuggestions(isOrigin: true)),
                const SizedBox(height: 10),
                _pointRow(_toCtrl, 'INPUT POINT B (e.g. SM City Calamba)',
                    AppColors.yellow, AppColors.yellowDark,
                    onTap: () => _showSuggestions(isOrigin: false)),
                if (_errorMsg.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_errorMsg, style: const TextStyle(
                      color: AppColors.red, fontSize: 12)),
                ],
              ]),
            )),

          // My location button
          Positioned(
            bottom: _showSheet ? 300 : 80, right: 16,
            child: _FloatBtn(
                icon: Icons.my_location,
                onTap: MapWidget.goToMyLocation)),

          // Start Navigation button
          if (!_showSheet)
            Positioned(bottom: 24, right: 16,
              child: GestureDetector(
                onTap: _loading ? null : _startNavigation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 14),
                  decoration: BoxDecoration(
                    color: _loading ? Colors.grey : AppColors.blue,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.4),
                        blurRadius: 16, offset: const Offset(0, 6))]),
                  child: _loading
                      ? const SizedBox(
                          width: 88,
                          child: Center(child: SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))))
                      : const Text('START NAVIGATION',
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13, letterSpacing: 0.8)),
                ),
              )),
        ])),
      ]),

      // ── Route result sheet ───────────────────────────────────────────────
      if (_showSheet && _directions != null)
        Positioned(bottom: 0, left: 0, right: 0,
          child: _RouteSheet(
            directions: _directions!,
            onClose: _clearRoute,
            onShare: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Route shared!'),
                    backgroundColor: AppColors.blue)),
            onSave: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Route saved!'),
                    backgroundColor: AppColors.blue)),
          )),
    ]);
  }

  Widget _pointRow(TextEditingController ctrl, String hint,
      Color dot, Color? dotBorder, {VoidCallback? onTap}) {
    return Row(children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: dot, shape: BoxShape.circle,
          border: dotBorder != null
              ? Border.all(color: dotBorder, width: 1.5) : null)),
      const SizedBox(width: 10),
      Expanded(child: GestureDetector(
        onTap: onTap,
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textLight,
                fontSize: 12, fontWeight: FontWeight.w600),
            border: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.lightGrey)),
            enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.lightGrey)),
            focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.blue, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            isDense: true,
            suffixIcon: ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear,
                        size: 16, color: AppColors.textLight),
                    onPressed: () { ctrl.clear(); setState(() {}); })
                : null,
          ),
          style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w600, color: AppColors.textDark),
          onChanged: (_) => setState(() {}),
        ),
      )),
    ]);
  }

  Future<void> _showSuggestions({required bool isOrigin}) async {
    final routes = await _routeRepo.getAll();
    final places = <String>{};
    for (final r in routes) {
      places.add(r.origin);
      places.add(r.destination);
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SheetHandle(),
        Text(isOrigin ? 'Select Starting Point' : 'Select Destination',
            style: const TextStyle(fontWeight: FontWeight.w800,
                fontSize: 16, color: AppColors.textDark)),
        const SizedBox(height: 8),
        Flexible(child: ListView(shrinkWrap: true,
          children: places.map((p) {
            final match = routes.where((r) =>
                isOrigin ? r.origin == p : r.destination == p).firstOrNull;
            return ListTile(
              leading: Icon(isOrigin ? Icons.circle : Icons.flag,
                  color: isOrigin ? AppColors.blue : AppColors.yellow,
                  size: 16),
              title: Text(p, style: const TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                if (match != null) {
                  if (isOrigin) {
                    _fromCtrl.text = p;
                    setState(() => _originPin = match.originLatLng);
                  } else {
                    _toCtrl.text = p;
                    setState(() => _destPin = match.destLatLng);
                  }
                }
              },
            );
          }).toList())),
        const SizedBox(height: 16),
      ]),
    );
  }
}

// ── Floating button ───────────────────────────────────────────────────────────
class _FloatBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _FloatBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: Colors.white, shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8, offset: const Offset(0, 2))]),
      child: Icon(icon, color: AppColors.blue, size: 22)),
  );
}

// ── Route Result Sheet ────────────────────────────────────────────────────────
class _RouteSheet extends StatefulWidget {
  final DirectionsResult directions;
  final VoidCallback onClose, onShare, onSave;
  const _RouteSheet({
    required this.directions,
    required this.onClose,
    required this.onShare,
    required this.onSave,
  });
  @override
  State<_RouteSheet> createState() => _RouteSheetState();
}

class _RouteSheetState extends State<_RouteSheet> {
  bool _showSteps = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.directions;
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65),
      decoration: const BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Center(child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 10),
        Flexible(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Header row
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(d.totalDuration, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800,
                    fontSize: 22)),
                Container(height: 1, width: 160,
                    color: Colors.white38,
                    margin: const EdgeInsets.symmetric(vertical: 4)),
                Text(d.totalDistance, style: const TextStyle(
                    color: Colors.white70, fontSize: 13)),
              ]),
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 34, height: 34,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const Center(child: Text('✕',
                      style: TextStyle(color: AppColors.textDark,
                          fontWeight: FontWeight.w800, fontSize: 13))))),
            ]),
            const SizedBox(height: 14),

            // Jeepney icon + fare toggle
            Row(children: [
              Container(
                width: 62, height: 62,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16)),
                child: Stack(alignment: Alignment.center, children: [
                  const SizedBox(width: 58, height: 58,
                      child: CustomPaint(painter: SunPainter())),
                  const Text('🚌', style: TextStyle(fontSize: 28)),
                ])),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Fare', style: TextStyle(
                    color: Colors.white70, fontSize: 12)),
                ListenableBuilder(listenable: AppState.instance,
                  builder: (_, __) {
                    const base = 20.0;
                    final fare = AppState.instance.isDiscounted
                        ? base * 0.80 : base;
                    return Row(children: [
                      Text('₱${fare.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w800, fontSize: 22)),
                      if (AppState.instance.isDiscounted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.yellow,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Text('20% OFF', style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w800,
                              color: AppColors.textDark))),
                      ],
                    ]);
                  }),
              ]),
              const Spacer(),
              const FareToggle(),
            ]),

            const SizedBox(height: 8),
            // Origin → Destination
            Row(children: [
              const Icon(Icons.circle, color: Colors.white54, size: 8),
              const SizedBox(width: 6),
              Expanded(child: Text(
                  '${d.origin.lat.toStringAsFixed(4)}, '
                  '${d.origin.lng.toStringAsFixed(4)}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis)),
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward,
                      color: Colors.white38, size: 14)),
              Expanded(child: Text(
                  '${d.destination.lat.toStringAsFixed(4)}, '
                  '${d.destination.lng.toStringAsFixed(4)}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis)),
            ]),

            // Turn-by-turn directions toggle
            if (d.steps.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() => _showSteps = !_showSteps),
                child: Row(children: [
                  const Icon(Icons.directions,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _showSteps
                        ? 'Hide Directions'
                        : 'Show Turn-by-Turn (${d.steps.length} steps)',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12,
                        decoration: TextDecoration.underline)),
                ])),
              if (_showSteps) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(children: d.steps.take(15)
                      .map((s) => _StepTile(step: s)).toList())),
              ],
            ],

            const SizedBox(height: 16),
            // Action buttons
            Row(children: [
              Expanded(child: YellowBtn(
                  label: 'Confirm', icon: Icons.check,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Navigation started! Enjoy your ride.'),
                            backgroundColor: AppColors.blue));
                  })),
              const SizedBox(width: 8),
              Expanded(child: YellowBtn(
                  label: 'Share',
                  icon: Icons.share_outlined,
                  onTap: widget.onShare)),
              const SizedBox(width: 8),
              Expanded(child: YellowBtn(
                  label: 'Save',
                  icon: Icons.bookmark_outline,
                  onTap: widget.onSave)),
            ]),
          ]),
        )),
      ]),
    );
  }
}

// ── Step tile ─────────────────────────────────────────────────────────────────
class _StepTile extends StatelessWidget {
  final DirectionStep step;
  const _StepTile({required this.step});

  IconData _icon() {
    final m = step.maneuver.toLowerCase();
    if (m.contains('left'))        return Icons.turn_left;
    if (m.contains('right'))       return Icons.turn_right;
    if (m.contains('arrive'))      return Icons.flag;
    if (m.contains('depart'))      return Icons.navigation;
    if (m.contains('roundabout'))  return Icons.roundabout_left;
    return Icons.straight;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle),
        child: Icon(_icon(), color: Colors.white, size: 16)),
      const SizedBox(width: 10),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(step.instruction, style: const TextStyle(
            color: Colors.white, fontSize: 12,
            fontWeight: FontWeight.w500)),
        Text('${step.distance} · ${step.duration}',
            style: const TextStyle(
                color: Colors.white54, fontSize: 10)),
      ])),
    ]),
  );
}
