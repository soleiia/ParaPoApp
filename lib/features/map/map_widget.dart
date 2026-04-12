// Unified map widget — flutter_map + OpenStreetMap.
// Works on Android, iOS, Windows, Linux, macOS. No API key needed for map tiles.
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:para_po/core/models/models.dart';
import 'package:para_po/core/theme/app_theme.dart';

const _kCabuyao = ll.LatLng(14.2724, 121.1241);

class MapWidget extends StatefulWidget {
  final List<AppLatLng>? directionsPolyline;
  final AppLatLng? originPin;
  final AppLatLng? destPin;
  final bool showRoute;

  const MapWidget({
    super.key,
    this.directionsPolyline,
    this.originPin,
    this.destPin,
    this.showRoute = false,
  });

  static final _ctrl = MapController();
  static _TileType _tileType = _TileType.street;

  static void goToMyLocation() {
    try { _ctrl.move(_kCabuyao, 14); } catch (_) {}
  }

  static void toggleMapType() {
    _tileType = _tileType == _TileType.street
        ? _TileType.satellite
        : _TileType.street;
  }

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

enum _TileType { street, satellite }

class _MapWidgetState extends State<MapWidget> {
  bool _mapError = false;

  List<ll.LatLng> _toLL(List<AppLatLng> pts) =>
      pts.map((p) => ll.LatLng(p.lat, p.lng)).toList();

  @override
  void didUpdateWidget(MapWidget old) {
    super.didUpdateWidget(old);
    final poly = widget.directionsPolyline;
    if (poly != null && poly.length > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute(poly));
    }
  }

  void _fitRoute(List<AppLatLng> pts) {
    try {
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
      MapWidget._ctrl.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds(sw, ne),
        padding: const EdgeInsets.all(60),
      ));
    } catch (_) {}
  }

  String get _tileUrl => MapWidget._tileType == _TileType.satellite
      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/'
        'World_Imagery/MapServer/tile/{z}/{y}/{x}'
      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  @override
  Widget build(BuildContext context) {
    final poly = widget.directionsPolyline;
    final orig = widget.originPin;
    final dest = widget.destPin;

    if (_mapError) {
      return _MapErrorPlaceholder(onRetry: () => setState(() => _mapError = false));
    }

    return FlutterMap(
      mapController: MapWidget._ctrl,
      options: const MapOptions(
        initialCenter: _kCabuyao,
        initialZoom: 13,
        minZoom: 5,
        maxZoom: 19,
        interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
      ),
      children: [
        // ── Tile layer ──────────────────────────────────────────────────────
        TileLayer(
          urlTemplate: _tileUrl,
          userAgentPackageName: 'com.example.para_po',
          // Fallback tiles if primary fails
          fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          errorTileCallback: (tile, err, stack) {
            // Don't setState here — just silently fail per tile
          },
          tileBuilder: (context, child, tile) => child,
        ),

        // ── Route polyline ───────────────────────────────────────────────────
        if (poly != null && poly.length > 1)
          PolylineLayer(polylines: [
            Polyline(
              points:      _toLL(poly),
              color:       AppColors.blue,
              strokeWidth: 5,
              borderColor: Colors.white.withValues(alpha: 0.5),
              borderStrokeWidth: 2,
            ),
          ]),

        // ── Markers ─────────────────────────────────────────────────────────
        MarkerLayer(markers: [
          if (orig != null)
            Marker(
              point:  ll.LatLng(orig.lat, orig.lng),
              width:  44,
              height: 52,
              child:  _Pin(color: AppColors.blue, icon: Icons.trip_origin),
            ),
          if (dest != null)
            Marker(
              point:  ll.LatLng(dest.lat, dest.lng),
              width:  44,
              height: 52,
              child:  _Pin(color: AppColors.yellow, icon: Icons.flag,
                  iconColor: AppColors.textDark),
            ),
        ]),

        // ── Attribution ─────────────────────────────────────────────────────
        RichAttributionWidget(
          popupInitialDisplayDuration: Duration.zero,
          attributions: [
            TextSourceAttribution(
              MapWidget._tileType == _TileType.satellite
                  ? 'Esri World Imagery'
                  : 'OpenStreetMap contributors',
            ),
          ],
        ),
      ],
    );
  }
}

// ── Pin marker ────────────────────────────────────────────────────────────────
class _Pin extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;
  const _Pin({required this.color, required this.icon,
      this.iconColor = Colors.white});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4),
              blurRadius: 8, offset: const Offset(0, 3))]),
        child: Icon(icon, color: iconColor, size: 20)),
      Container(width: 2.5, height: 10,
          decoration: BoxDecoration(color: color,
              borderRadius: BorderRadius.circular(2))),
      Container(width: 6, height: 3,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3))),
    ],
  );
}

// ── Error placeholder ─────────────────────────────────────────────────────────
class _MapErrorPlaceholder extends StatelessWidget {
  final VoidCallback onRetry;
  const _MapErrorPlaceholder({required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFE8F0FE),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16)]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off, color: AppColors.textLight, size: 48),
          const SizedBox(height: 12),
          const Text('Map unavailable', style: TextStyle(
              color: AppColors.textDark, fontSize: 16,
              fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Check your internet connection',
              style: TextStyle(color: AppColors.textMid, fontSize: 13)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: AppColors.blue,
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Retry', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)))),
        ])),
    ])),
  );
}
