// Unified map widget using flutter_map + OpenStreetMap.
// Works on Android, iOS, Windows, Linux, macOS — no API key needed.
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

  // Static map controller — accessed by map_page for camera control
  static final _ctrl = MapController();

  static void goToMyLocation() {
    _ctrl.move(_kCabuyao, 14);
  }

  static void toggleMapType() {
    // flutter_map tile layer switching handled via MapTileType below
    MapWidget._tileType = MapWidget._tileType == _TileType.street
        ? _TileType.satellite
        : _TileType.street;
  }

  static _TileType _tileType = _TileType.street;

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

enum _TileType { street, satellite }

class _MapWidgetState extends State<MapWidget> {
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
  }

  String get _tileUrl => MapWidget._tileType == _TileType.satellite
      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  @override
  Widget build(BuildContext context) {
    final poly = widget.directionsPolyline;
    final orig = widget.originPin;
    final dest = widget.destPin;

    return FlutterMap(
      mapController: MapWidget._ctrl,
      options: const MapOptions(
        initialCenter: _kCabuyao,
        initialZoom: 13,
        interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
      ),
      children: [
        // Map tile layer (street or satellite)
        TileLayer(
          urlTemplate: _tileUrl,
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
              height: 50,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 34, height: 34,
                  decoration: const BoxDecoration(
                      color: AppColors.blue, shape: BoxShape.circle),
                  child: const Icon(Icons.trip_origin,
                      color: Colors.white, size: 20)),
                Container(width: 2, height: 8, color: AppColors.blue),
              ]),
            ),
          if (dest != null)
            Marker(
              point:  ll.LatLng(dest.lat, dest.lng),
              width:  40,
              height: 50,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 34, height: 34,
                  decoration: const BoxDecoration(
                      color: AppColors.yellow, shape: BoxShape.circle),
                  child: const Icon(Icons.flag,
                      color: AppColors.textDark, size: 20)),
                Container(width: 2, height: 8, color: AppColors.yellow),
              ]),
            ),
        ]),

        // Attribution (required by OSM/ArcGIS terms)
        RichAttributionWidget(attributions: [
          TextSourceAttribution(
            MapWidget._tileType == _TileType.satellite
                ? 'Esri World Imagery'
                : 'OpenStreetMap contributors',
          ),
        ]),
      ],
    );
  }
}
