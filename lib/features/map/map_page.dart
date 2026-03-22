import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:para_po/core/theme/app_theme.dart';
import 'package:para_po/shared/widgets/widgets.dart';

// Default center: Cabuyao, Laguna, Philippines
const _kCabuyao = LatLng(14.2738, 121.1251);

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _fromCtrl = TextEditingController();
  final _toCtrl   = TextEditingController();

  GoogleMapController? _mapController;
  bool _showSheet  = false;
  bool _navigating = false;
  double _fare    = 0;
  int    _minutes = 0;

  // Map state
  final Set<Marker>   _markers   = {};
  final Set<Polyline> _polylines = {};
  MapType _mapType = MapType.normal;

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Optional: apply custom map style here
  }

  void _startNavigation() {
    if (_fromCtrl.text.trim().isEmpty || _toCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both Point A and Point B'),
          backgroundColor: AppColors.blue,
        ),
      );
      return;
    }

    // In a real app you would call a Directions API here.
    // For now we simulate a route with two markers.
    final rng = math.Random();
    final pointA = LatLng(
      _kCabuyao.latitude  + (rng.nextDouble() - 0.5) * 0.02,
      _kCabuyao.longitude + (rng.nextDouble() - 0.5) * 0.02,
    );
    final pointB = LatLng(
      _kCabuyao.latitude  + (rng.nextDouble() - 0.5) * 0.02,
      _kCabuyao.longitude + (rng.nextDouble() - 0.5) * 0.02,
    );

    setState(() {
      _fare    = 13.0 + (rng.nextDouble() * 15);
      _minutes = 2 + rng.nextInt(20);
      _showSheet  = true;
      _navigating = false;

      // Place markers
      _markers
        ..clear()
        ..addAll([
          Marker(
            markerId: const MarkerId('pointA'),
            position: pointA,
            infoWindow: InfoWindow(title: 'Point A', snippet: _fromCtrl.text),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
          Marker(
            markerId: const MarkerId('pointB'),
            position: pointB,
            infoWindow: InfoWindow(title: 'Point B', snippet: _toCtrl.text),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          ),
        ]);

      // Draw a straight line between the two points
      // (real app: use Directions API polyline)
      _polylines
        ..clear()
        ..add(Polyline(
          polylineId: const PolylineId('route'),
          points: [pointA, pointB],
          color: AppColors.blue,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ));
    });

    // Animate camera to show both points
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            math.min(pointA.latitude,  pointB.latitude),
            math.min(pointA.longitude, pointB.longitude),
          ),
          northeast: LatLng(
            math.max(pointA.latitude,  pointB.latitude),
            math.max(pointA.longitude, pointB.longitude),
          ),
        ),
        80, // padding
      ),
    );
  }

  void _confirmRoute() {
    setState(() => _navigating = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() { _navigating = false; _showSheet = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚌 Navigation started! Enjoy your ride.'),
          backgroundColor: AppColors.blue,
        ),
      );
    });
  }

  void _toggleMapType() {
    setState(() {
      _mapType = _mapType == MapType.normal ? MapType.satellite : MapType.normal;
    });
  }

  void _myLocation() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(target: _kCabuyao, zoom: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Column(children: [
        // ── Top blue bar ──────────────────────────────────────────────────
        Container(
          color: AppColors.blue,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                const Text('Cabuyao',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                const Spacer(),
                // Map type toggle
                GestureDetector(
                  onTap: _toggleMapType,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10)),
                    child: Icon(
                      _mapType == MapType.normal ? Icons.satellite_alt : Icons.map,
                      color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                // Filter
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filter coming soon'),
                      backgroundColor: AppColors.blue)),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.tune, color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ),
          ),
        ),

        // ── Google Map ────────────────────────────────────────────────────
        Expanded(
          child: Stack(children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: _kCabuyao,
                zoom: 13,
              ),
              mapType: _mapType,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false, // we use custom button
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),

            // ── Route input card ─────────────────────────────────────────
            Positioned(top: 16, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Column(children: [
                  // Point A
                  Row(children: [
                    Container(width: 10, height: 10,
                      decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(
                      controller: _fromCtrl,
                      decoration: const InputDecoration(
                        hintText: 'INPUT POINT A',
                        hintStyle: TextStyle(color: AppColors.textLight, fontSize: 12,
                          fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.lightGrey)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.lightGrey)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.blue, width: 1.5)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    )),
                  ]),
                  const SizedBox(height: 10),
                  // Point B
                  Row(children: [
                    Container(width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.yellow, shape: BoxShape.circle,
                        border: Border.all(color: AppColors.yellowDark, width: 1.5))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(
                      controller: _toCtrl,
                      decoration: const InputDecoration(
                        hintText: 'INPUT POINT B',
                        hintStyle: TextStyle(color: AppColors.textLight, fontSize: 12,
                          fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.lightGrey)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.lightGrey)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.blue, width: 1.5)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    )),
                  ]),
                ]),
              ),
            ),

            // ── My location button ────────────────────────────────────────
            Positioned(
              bottom: _showSheet ? 240 : 80,
              right: 16,
              child: GestureDetector(
                onTap: _myLocation,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.my_location, color: AppColors.blue, size: 22),
                ),
              ),
            ),

            // ── Start Navigation button ───────────────────────────────────
            Positioned(
              bottom: _showSheet ? 240 : 24,
              right: 16,
              child: GestureDetector(
                onTap: _startNavigation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.4),
                      blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: const Text('START NAVIGATION',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700,
                      fontSize: 13, letterSpacing: 0.8)),
                ),
              ),
            ),
          ]),
        ),
      ]),

      // ── Route result sheet ────────────────────────────────────────────────
      if (_showSheet)
        Positioned(bottom: 0, left: 0, right: 0,
          child: _RouteSheet(
            fare: _fare,
            minutes: _minutes,
            from: _fromCtrl.text,
            to: _toCtrl.text,
            navigating: _navigating,
            onClose:   () => setState(() { _showSheet = false; _markers.clear(); _polylines.clear(); }),
            onConfirm: _confirmRoute,
            onShare: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Route shared!'), backgroundColor: AppColors.blue)),
            onSave: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Route saved!'), backgroundColor: AppColors.blue)),
          )),
    ]);
  }
}

// ── Route Result Sheet ────────────────────────────────────────────────────────
class _RouteSheet extends StatelessWidget {
  final double fare;
  final int minutes;
  final String from, to;
  final bool navigating;
  final VoidCallback onClose, onConfirm, onShare, onSave;

  const _RouteSheet({
    required this.fare, required this.minutes,
    required this.from,  required this.to,
    required this.navigating,
    required this.onClose, required this.onConfirm,
    required this.onShare, required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$minutes min',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
              Container(height: 1, width: 140, color: Colors.white38,
                margin: const EdgeInsets.symmetric(vertical: 4)),
              const Text('Transportation',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ]),
            GestureDetector(onTap: onClose,
              child: Container(width: 34, height: 34,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Center(child: Text('✕',
                  style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 13))))),
          ]),

          const SizedBox(height: 14),

          Row(children: [
            Container(width: 62, height: 62,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16)),
              child: const Stack(alignment: Alignment.center, children: [
                SizedBox(width: 58, height: 58, child: CustomPaint(painter: SunPainter())),
                Text('🚌', style: TextStyle(fontSize: 28)),
              ])),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Fare', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('₱ ${fare.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
            ]),
          ]),

          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.circle, color: Colors.white54, size: 8),
            const SizedBox(width: 6),
            Expanded(child: Text(from,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis)),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, color: Colors.white38, size: 14)),
            Expanded(child: Text(to,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis)),
          ]),

          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: YellowBtn(
              label: navigating ? 'Loading…' : 'Confirm',
              icon: Icons.check, onTap: onConfirm)),
            const SizedBox(width: 8),
            Expanded(child: YellowBtn(label: 'Share', icon: Icons.share_outlined, onTap: onShare)),
            const SizedBox(width: 8),
            Expanded(child: YellowBtn(label: 'Save', icon: Icons.bookmark_outline, onTap: onSave)),
          ]),
        ]),
      ),
    );
  }
}
