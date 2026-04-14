import 'package:flutter/material.dart';
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
  // ── Controllers ────────────────────────────────────────────────────────────
  final _fromCtrl    = TextEditingController();
  final _toCtrl      = TextEditingController();
  final _fromFocus   = FocusNode();
  final _toFocus     = FocusNode();
  final _routeRepo   = RouteRepository();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _showSheet   = false;
  bool _loading     = false;
  bool _isSatellite = false;
  DirectionsResult? _directions;
  AppLatLng? _originPin;
  AppLatLng? _destPin;
  String _errorMsg  = '';
  double _selectedFare = 0.0;  // actual fare from the selected route

  // All unique places loaded from DB
  List<String> _allPlaces   = [];
  List<RouteModel> _allRoutes = [];

  // Live filtered suggestions
  List<String> _fromSuggestions = [];
  List<String> _toSuggestions   = [];

  // Which field is focused
  bool _fromActive = false;
  bool _toActive   = false;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    AppState.instance.addListener(_onStateChange);
    _fromFocus.addListener(_onFromFocus);
    _toFocus.addListener(_onToFocus);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkPendingRoute());
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onStateChange);
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  // ── Load places from DB ────────────────────────────────────────────────────
  Future<void> _loadRoutes() async {
    _allRoutes = await _routeRepo.getAll();
    final places = <String>{};
    for (final r in _allRoutes) {
      places.add(r.origin);
      places.add(r.destination);
    }
    if (mounted) {
      setState(() {
        _allPlaces         = places.toList()..sort();
        _fromSuggestions   = _allPlaces;
        _toSuggestions     = _allPlaces;
      });
    }
  }

  // ── Focus listeners ────────────────────────────────────────────────────────
  void _onFromFocus() {
    setState(() {
      _fromActive = _fromFocus.hasFocus;
      if (_fromFocus.hasFocus) {
        _toActive = false;
        _filterFrom(_fromCtrl.text);
      }
    });
  }

  void _onToFocus() {
    setState(() {
      _toActive = _toFocus.hasFocus;
      if (_toFocus.hasFocus) {
        _fromActive = false;
        _filterTo(_toCtrl.text);
      }
    });
  }

  // ── Live filter helpers ────────────────────────────────────────────────────
  void _filterFrom(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      _fromSuggestions = query.isEmpty
          ? _allPlaces
          : _allPlaces
              .where((p) => p.toLowerCase().contains(query))
              .toList();
    });
  }

  void _filterTo(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      _toSuggestions = query.isEmpty
          ? _allPlaces
          : _allPlaces
              .where((p) => p.toLowerCase().contains(query))
              .toList();
    });
  }

  // ── Select a suggestion ────────────────────────────────────────────────────
  void _selectFrom(String place) {
    _fromCtrl.text = place;
    _fromFocus.unfocus();
    setState(() { _fromActive = false; });
    // Auto-focus destination if empty
    if (_toCtrl.text.isEmpty) {
      Future.delayed(const Duration(milliseconds: 100),
          () => _toFocus.requestFocus());
    }
  }

  void _selectTo(String place) {
    _toCtrl.text = place;
    _toFocus.unfocus();
    setState(() { _toActive = false; });
  }

  // ── Dismiss suggestions when tapping outside ───────────────────────────────
  void _dismissSuggestions() {
    _fromFocus.unfocus();
    _toFocus.unfocus();
    setState(() { _fromActive = false; _toActive = false; });
  }

  // ── AppState listener ──────────────────────────────────────────────────────
  void _onStateChange() {
    if (AppState.instance.hasPendingRoute) _checkPendingRoute();
  }

  void _checkPendingRoute() {
    if (!AppState.instance.hasPendingRoute) return;
    final origin    = AppState.instance.pendingOrigin!;
    final dest      = AppState.instance.pendingDestination!;
    final fare      = AppState.instance.pendingFare ?? 0.0;
    final oLat      = AppState.instance.pendingOriginLat;
    final oLng      = AppState.instance.pendingOriginLng;
    final dLat      = AppState.instance.pendingDestLat;
    final dLng      = AppState.instance.pendingDestLng;
    AppState.instance.clearPendingRoute();
    setState(() {
      _fromCtrl.text = origin;
      _toCtrl.text   = dest;
      _selectedFare  = fare;
      _fromActive    = false;
      _toActive      = false;
      // Pre-set pins from the route's stored coordinates
      if (oLat != null && oLng != null) _originPin = AppLatLng(oLat, oLng);
      if (dLat != null && dLng != null) _destPin   = AppLatLng(dLat, dLng);
    });
    _startNavigation();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  Future<void> _startNavigation() async {
    _dismissSuggestions();
    final from = _fromCtrl.text.trim();
    final to   = _toCtrl.text.trim();

    if (from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter both Point A and Point B'),
          backgroundColor: AppColors.blue));
      return;
    }

    setState(() { _loading = true; _errorMsg = ''; });

    // Use Cabuyao-area coordinates as starting defaults
    AppLatLng? origin = _originPin;
    AppLatLng? dest   = _destPin;

    // If no pins yet, look up the route in DB to get real coordinates + fare
    if (origin == null || dest == null) {
      final routes = await _routeRepo.search(from);
      final match  = routes.where((r) =>
          r.destination.toLowerCase().contains(to.toLowerCase()))
          .firstOrNull;
      if (match != null) {
        origin = match.originLatLng;
        dest   = match.destLatLng;
        setState(() {
          _originPin    = origin;
          _destPin      = dest;
          _selectedFare = match.fare;
        });
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
      _showSheet    = false;
      _directions   = null;
      _originPin    = null;
      _destPin      = null;
      _errorMsg     = '';
      _fromActive   = false;
      _toActive     = false;
      _selectedFare = 0.0;
    });
    _fromCtrl.clear();
    _toCtrl.clear();
    _filterFrom('');
    _filterTo('');
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final showFromDropdown = _fromActive && _fromSuggestions.isNotEmpty;
    final showToDropdown   = _toActive   && _toSuggestions.isNotEmpty;

    return GestureDetector(
      onTap: _dismissSuggestions,
      behavior: HitTestBehavior.translucent,
      child: Stack(children: [
        Column(children: [
          // ── Top bar ────────────────────────────────────────────────────────
          Container(color: AppColors.blue,
            child: SafeArea(bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(children: [
                  // Title — Flexible so it shrinks on narrow screens
                  Flexible(
                    child: Text('Para Po 🚌',
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w800, fontSize: 18),
                        overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  // Satellite toggle
                  GestureDetector(
                    onTap: () {
                      setState(() => _isSatellite = !_isSatellite);
                      MapWidget.toggleMapType();
                    },
                    child: Container(
                      width: 32, height: 32,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                          color: _isSatellite
                              ? AppColors.yellow
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(
                          _isSatellite ? Icons.map : Icons.satellite_alt,
                          color: _isSatellite
                              ? AppColors.textDark : Colors.white,
                          size: 17))),
                  // Compact fare toggle
                  const _CompactFareToggle(),
                ]),
              )),
          ),

          // ── Map ────────────────────────────────────────────────────────────
          Expanded(child: Stack(children: [
            Positioned.fill(child: MapWidget(
              directionsPolyline: _directions?.polylinePoints,
              originPin: _originPin,
              destPin:   _destPin,
              showRoute: _showSheet,
            )),

            // ── Search input card ─────────────────────────────────────────
            Positioned(top: 16, left: 16, right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Input card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.13),
                          blurRadius: 16, offset: const Offset(0, 4))]),
                    child: Column(children: [
                      // ── Point A ─────────────────────────────────────────
                      _SearchField(
                        controller: _fromCtrl,
                        focusNode:  _fromFocus,
                        hint: 'Point A – e.g. Cabuyao City Hall',
                        dot: AppColors.blue,
                        dotBorder: null,
                        isActive: _fromActive,
                        onChanged: _filterFrom,
                        onClear: () {
                          _fromCtrl.clear();
                          _filterFrom('');
                          setState(() {});
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Divider(color: AppColors.divider, height: 16)),
                      // ── Point B ─────────────────────────────────────────
                      _SearchField(
                        controller: _toCtrl,
                        focusNode:  _toFocus,
                        hint: 'Point B – e.g. SM City Calamba',
                        dot: AppColors.yellow,
                        dotBorder: AppColors.yellowDark,
                        isActive: _toActive,
                        onChanged: _filterTo,
                        onClear: () {
                          _toCtrl.clear();
                          _filterTo('');
                          setState(() {});
                        },
                      ),
                    ]),
                  ),

                  // ── Point A dropdown ──────────────────────────────────────
                  if (showFromDropdown)
                    _SuggestionDropdown(
                      suggestions: _fromSuggestions,
                      query:       _fromCtrl.text,
                      isOrigin:    true,
                      allRoutes:   _allRoutes,
                      onSelect:    _selectFrom,
                    ),

                  // ── Point B dropdown ──────────────────────────────────────
                  if (showToDropdown)
                    _SuggestionDropdown(
                      suggestions: _toSuggestions,
                      query:       _toCtrl.text,
                      isOrigin:    false,
                      allRoutes:   _allRoutes,
                      onSelect:    _selectTo,
                    ),

                  if (_errorMsg.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.red.withValues(alpha: 0.3))),
                      child: Row(children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_errorMsg,
                            style: const TextStyle(
                                color: AppColors.red, fontSize: 12))),
                      ])),
                ],
              )),

            // My location button
            Positioned(
              bottom: _showSheet ? 300 : 80, right: 16,
              child: _FloatBtn(
                  icon: Icons.my_location,
                  onTap: MapWidget.goToMyLocation)),

            // Start Navigation button
            if (!_showSheet && !showFromDropdown && !showToDropdown)
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
                          blurRadius: 16,
                          offset: const Offset(0, 6))]),
                    child: _loading
                        ? const SizedBox(width: 88,
                            child: Center(child: SizedBox(width: 18, height: 18,
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

        // Route sheet
        if (_showSheet && _directions != null)
          Positioned(bottom: 0, left: 0, right: 0,
            child: _RouteSheet(
              directions:   _directions!,
              fromText:     _fromCtrl.text,
              toText:       _toCtrl.text,
              selectedFare: _selectedFare,
              onClose: _clearRoute,
              onShare: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Route shared!'),
                      backgroundColor: AppColors.blue)),
              onSave: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Route saved!'),
                      backgroundColor: AppColors.blue)),
            )),
      ]),
    );
  }
}

// ── Search field ──────────────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final Color dot;
  final Color? dotBorder;
  final bool isActive;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.dot,
    required this.dotBorder,
    required this.isActive,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(
              color: dot, shape: BoxShape.circle,
              border: dotBorder != null
                  ? Border.all(color: dotBorder!, width: 1.5)
                  : null)),
      const SizedBox(width: 10),
      Expanded(child: TextField(
        controller:  controller,
        focusNode:   focusNode,
        style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w500, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText:  hint,
          hintStyle: const TextStyle(color: AppColors.textLight,
              fontSize: 12, fontWeight: FontWeight.w400),
          border:        InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense:         true,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.close,
                      size: 15, color: AppColors.textLight))
              : null,
        ),
        onChanged: onChanged,
      )),
      if (isActive)
        Icon(Icons.search, color: AppColors.blue.withValues(alpha: 0.6), size: 18),
    ]);
  }
}

// ── Suggestion dropdown ───────────────────────────────────────────────────────
class _SuggestionDropdown extends StatelessWidget {
  final List<String>    suggestions;
  final String          query;
  final bool            isOrigin;
  final List<RouteModel> allRoutes;
  final ValueChanged<String> onSelect;

  const _SuggestionDropdown({
    required this.suggestions,
    required this.query,
    required this.isOrigin,
    required this.allRoutes,
    required this.onSelect,
  });

  /// Count how many routes start from / go to this place
  int _routeCount(String place) {
    return allRoutes.where((r) =>
        isOrigin ? r.origin == place : r.destination == place).length;
  }

  /// Highlight matched portion of text
  Widget _highlightText(String text, String query) {
    if (query.isEmpty) {
      return Text(text, style: const TextStyle(
          color: AppColors.textDark, fontSize: 13,
          fontWeight: FontWeight.w500));
    }
    final lower  = text.toLowerCase();
    final qLower = query.toLowerCase();
    final idx    = lower.indexOf(qLower);
    if (idx == -1) {
      return Text(text, style: const TextStyle(
          color: AppColors.textDark, fontSize: 13));
    }
    return RichText(text: TextSpan(
      style: const TextStyle(color: AppColors.textDark, fontSize: 13),
      children: [
        TextSpan(text: text.substring(0, idx)),
        TextSpan(text: text.substring(idx, idx + query.length),
            style: const TextStyle(
                color: AppColors.blue, fontWeight: FontWeight.w800)),
        TextSpan(text: text.substring(idx + query.length)),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Cap at 6 visible items, show scroll for more
    const maxVisible = 6;
    final itemCount  = suggestions.length;
    final showCount  = itemCount.clamp(0, maxVisible);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16, offset: const Offset(0, 4))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Icon(isOrigin ? Icons.location_on : Icons.flag,
                  color: isOrigin ? AppColors.blue : AppColors.yellow,
                  size: 15),
              const SizedBox(width: 6),
              Text(isOrigin ? 'Starting points' : 'Destinations',
                  style: const TextStyle(color: AppColors.textMid,
                      fontSize: 11, fontWeight: FontWeight.w600,
                      letterSpacing: 0.3)),
              const Spacer(),
              Text('${suggestions.length} result${suggestions.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: AppColors.textLight,
                      fontSize: 11)),
            ]),
          ),
          const Divider(color: AppColors.divider, height: 1),
          // Items (scrollable if more than maxVisible)
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: showCount * 56.0),
            child: ListView.separated(
              padding:        EdgeInsets.zero,
              shrinkWrap:     true,
              itemCount:      itemCount,
              separatorBuilder: (_, __) => const Divider(
                  color: AppColors.divider, height: 1, indent: 50),
              itemBuilder: (_, i) {
                final place = suggestions[i];
                final count = _routeCount(place);
                return InkWell(
                  onTap: () => onSelect(place),
                  borderRadius: i == itemCount - 1
                      ? const BorderRadius.vertical(
                          bottom: Radius.circular(16))
                      : BorderRadius.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(children: [
                      // Icon
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: isOrigin
                              ? AppColors.blue.withValues(alpha: 0.1)
                              : AppColors.yellow.withValues(alpha: 0.15),
                          shape: BoxShape.circle),
                        child: Icon(
                            isOrigin ? Icons.directions : Icons.place,
                            color: isOrigin
                                ? AppColors.blue : AppColors.yellowDark,
                            size: 15)),
                      const SizedBox(width: 12),
                      // Text
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        _highlightText(place, query),
                        if (count > 0)
                          Text('$count route${count == 1 ? '' : 's'} available',
                              style: const TextStyle(
                                  color: AppColors.textLight, fontSize: 11)),
                      ])),
                      // Arrow
                      const Icon(Icons.north_west,
                          color: AppColors.textLight, size: 14),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact Fare Toggle (fits in narrow sidebar) ─────────────────────────────
// Shows just an icon+label, no border radius padding waste
class _CompactFareToggle extends StatelessWidget {
  const _CompactFareToggle();
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
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              color: disc
                  ? AppColors.yellow
                  : Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(disc ? Icons.percent : Icons.attach_money,
                  color: disc ? AppColors.textDark : Colors.white, size: 12),
              const SizedBox(width: 3),
              Text(disc ? 'Disc.' : 'Reg.',
                  style: TextStyle(
                      color: disc ? AppColors.textDark : Colors.white,
                      fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
          ),
        );
      },
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
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Icon(icon, color: AppColors.blue, size: 22)),
  );
}

// ── Route Result Sheet ────────────────────────────────────────────────────────
class _RouteSheet extends StatefulWidget {
  final DirectionsResult directions;
  final String fromText, toText;
  final double selectedFare;
  final VoidCallback onClose, onShare, onSave;

  const _RouteSheet({
    required this.directions,
    required this.fromText,
    required this.toText,
    required this.selectedFare,
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
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 10),
        Flexible(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Header
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.totalDuration, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800,
                    fontSize: 22)),
                Container(height: 1, width: 160, color: Colors.white38,
                    margin: const EdgeInsets.symmetric(vertical: 4)),
                Text(d.totalDistance, style: const TextStyle(
                    color: Colors.white70, fontSize: 13)),
              ]),
              GestureDetector(onTap: widget.onClose,
                child: Container(width: 34, height: 34,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const Center(child: Text('✕', style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800, fontSize: 13))))),
            ]),
            const SizedBox(height: 14),

            // Jeepney + route text + fare toggle
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 56, height: 56,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14)),
                child: Stack(alignment: Alignment.center, children: [
                  const SizedBox(width: 52, height: 52,
                      child: CustomPaint(painter: SunPainter())),
                  const Text('🚌', style: TextStyle(fontSize: 26)),
                ])),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.fromText,
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Container(width: 1, height: 12,
                        color: Colors.white38,
                        margin: const EdgeInsets.only(left: 2)),
                  ])),
                Text(widget.toText,
                    style: const TextStyle(color: Colors.white70,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ])),
              const SizedBox(width: 8),
              // Fare
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                ListenableBuilder(listenable: AppState.instance,
                    builder: (_, __) {
                  // Use the actual route fare, or show "See route" if unknown
                  final base = widget.selectedFare > 0 ? widget.selectedFare : null;
                  final fare = base != null
                      ? (AppState.instance.isDiscounted ? base * 0.80 : base)
                      : null;
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(fare != null ? '₱${fare.toStringAsFixed(2)}' : '—',
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w800, fontSize: 20)),
                    if (AppState.instance.isDiscounted && fare != null)
                      const Text('20% OFF', style: TextStyle(
                          color: AppColors.yellow, fontSize: 10,
                          fontWeight: FontWeight.w700)),
                  ]);
                }),
                const SizedBox(height: 6),
                const FareToggle(),
              ]),
            ]),

            // Turn-by-turn
            if (d.steps.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() => _showSteps = !_showSteps),
                child: Row(children: [
                  const Icon(Icons.directions,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(_showSteps
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
            Row(children: [
              Expanded(child: YellowBtn(label: 'Confirm',
                  icon: Icons.check,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Navigation started! Enjoy your ride.'),
                          backgroundColor: AppColors.blue)))),
              const SizedBox(width: 8),
              Expanded(child: YellowBtn(label: 'Share',
                  icon: Icons.share_outlined, onTap: widget.onShare)),
              const SizedBox(width: 8),
              Expanded(child: YellowBtn(label: 'Save',
                  icon: Icons.bookmark_outline, onTap: widget.onSave)),
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
    if (m.contains('left'))       return Icons.turn_left;
    if (m.contains('right'))      return Icons.turn_right;
    if (m.contains('arrive'))     return Icons.flag;
    if (m.contains('depart'))     return Icons.navigation;
    if (m.contains('roundabout')) return Icons.roundabout_left;
    return Icons.straight;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 28, height: 28,
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
