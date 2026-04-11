// Desktop map using flutter_map + OpenStreetMap tiles (Windows/Linux/macOS)
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:para_po/core/theme/app_theme.dart';
import 'package:para_po/core/models/models.dart';

class DesktopMapWidget extends StatefulWidget {
  final List<AppLatLng>? directionsPolyline;
  final AppLatLng? originPin;
  final AppLatLng? destPin;

  const DesktopMapWidget({
    super.key,
    this.directionsPolyline,
    this.originPin,
    this.destPin,
  });

  @override
  State<DesktopMapWidget> createState() => _DesktopMapWidgetState();
}

class _DesktopMapWidgetState extends State<DesktopMapWidget> {
  final _mapCtrl = MapController();
  static const _cabuyao = ll.LatLng(14.2724, 121.1241);

  @override
  void didUpdateWidget(DesktopMapWidget old) {
    super.didUpdateWidget(old);
    final poly = widget.directionsPolyline;
    if (poly != null && poly.length > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitToRoute(poly));
    }
  }

  void _fitToRoute(List<AppLatLng> pts) {
    final lats = pts.map((p) => p.lat).toList();
    final lngs = pts.map((p) => p.lng).toList();
    final sw = ll.LatLng(
      lats.reduce((a, b) => a < b ? a : b),
      lngs.reduce((a, b) => a < b ? a : b),
    );
    final ne = ll.LatLng(
      lats.reduce((a, b) => a > b ? a : b),
      lngs.reduce((a, b) => a > b ? a : b),
    );
    _mapCtrl.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(sw, ne),
      padding: const EdgeInsets.all(60),
    ));
  }

  List<ll.LatLng> _toLL(List<AppLatLng> pts) =>
      pts.map((p) => ll.LatLng(p.lat, p.lng)).toList();

  @override
  Widget build(BuildContext context) {
    final poly = widget.directionsPolyline;
    final orig = widget.originPin;
    final dest = widget.destPin;

    return FlutterMap(
      mapController: _mapCtrl,
      options: const MapOptions(
        initialCenter: _cabuyao,
        initialZoom: 13,
        interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
      ),
      children: [
        // OpenStreetMap tiles — free, no API key required
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.para_po',
        ),

        // Route polyline
        if (poly != null && poly.length > 1)
          PolylineLayer(polylines: [
            Polyline(
              points:      _toLL(poly),
              color:       AppColors.blue,
              strokeWidth: 5,
            ),
          ]),

        // Markers
        MarkerLayer(markers: [
          if (orig != null)
            Marker(
              point:  ll.LatLng(orig.lat, orig.lng),
              width:  40,
              height: 48,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(
                      color: AppColors.blue, shape: BoxShape.circle),
                  child: const Icon(Icons.location_on,
                      color: Colors.white, size: 20),
                ),
                Container(width: 2, height: 8, color: AppColors.blue),
              ]),
            ),
          if (dest != null)
            Marker(
              point:  ll.LatLng(dest.lat, dest.lng),
              width:  40,
              height: 48,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(
                      color: AppColors.yellow, shape: BoxShape.circle),
                  child: const Icon(Icons.flag,
                      color: AppColors.textDark, size: 20),
                ),
                Container(width: 2, height: 8, color: AppColors.yellow),
              ]),
            ),
        ]),

        // OSM attribution (required by terms of service)
        const RichAttributionWidget(attributions: [
          TextSourceAttribution('OpenStreetMap contributors'),
        ]),
      ],
    );
  }
}
