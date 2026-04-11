import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:para_po/core/models/models.dart';
import 'package:para_po/core/constants.dart';

class DirectionsService {
  static const _googleBase = 'https://maps.googleapis.com/maps/api/directions/json';
  static const _osrmBase   = 'https://router.project-osrm.org/route/v1/driving';

  static Future<DirectionsResult?> getDirections({
    required AppLatLng origin,
    required AppLatLng destination,
  }) async {
    try {
      final isDesktop = !kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
      return isDesktop
          ? await _osrmDirections(origin, destination)
          : await _googleDirections(origin, destination);
    } catch (_) {
      return null;
    }
  }

  // ── Google Directions API ─────────────────────────────────────────────────
  static Future<DirectionsResult?> _googleDirections(
      AppLatLng o, AppLatLng d) async {
    final uri = Uri.parse(_googleBase).replace(queryParameters: {
      'origin':      '${o.lat},${o.lng}',
      'destination': '${d.lat},${d.lng}',
      'mode':        'driving',
      'key':         AppConstants.googleMapsApiKey,
      'region':      'PH',
    });
    final resp =
        await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return null;
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if (json['status'] != 'OK') return null;

    final route = (json['routes'] as List).first as Map<String, dynamic>;
    final leg   = (route['legs']  as List).first as Map<String, dynamic>;
    final pts   = _decode(route['overview_polyline']['points'] as String);

    final steps = <DirectionStep>[];
    for (final s in leg['steps'] as List) {
      final st  = s as Map<String, dynamic>;
      final el  = st['end_location'] as Map<String, dynamic>;
      final ins = (st['html_instructions'] as String? ?? '')
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .trim();
      steps.add(DirectionStep(
        instruction: ins,
        distance:    (st['distance'] as Map)['text'] as String,
        duration:    (st['duration'] as Map)['text'] as String,
        endLocation: AppLatLng(
            (el['lat'] as num).toDouble(), (el['lng'] as num).toDouble()),
        maneuver: st['maneuver'] as String? ?? '',
      ));
    }
    return DirectionsResult(
      polylinePoints: pts,
      steps:          steps,
      totalDistance:  (leg['distance'] as Map)['text'] as String,
      totalDuration:  (leg['duration'] as Map)['text'] as String,
      origin:         o,
      destination:    d,
    );
  }

  // ── OSRM Directions API (desktop, free, no key) ───────────────────────────
  static Future<DirectionsResult?> _osrmDirections(
      AppLatLng o, AppLatLng d) async {
    final url =
        '$_osrmBase/${o.lng},${o.lat};${d.lng},${d.lat}'
        '?overview=full&geometries=polyline&steps=true';
    final resp =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return null;
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if (json['code'] != 'Ok') return null;

    final route = (json['routes'] as List).first as Map<String, dynamic>;
    final leg   = (route['legs']  as List).first as Map<String, dynamic>;
    final pts   = _decode(route['geometry'] as String);

    final steps = <DirectionStep>[];
    for (final s in leg['steps'] as List) {
      final st  = s as Map<String, dynamic>;
      final mv  = st['maneuver'] as Map<String, dynamic>;
      final loc = mv['location'] as List;
      steps.add(DirectionStep(
        instruction: _inst(
            mv['type']     as String? ?? '',
            mv['modifier'] as String? ?? '',
            st['name']     as String? ?? ''),
        distance:    _fmtDist((st['distance'] as num).toDouble()),
        duration:    _fmtDur((st['duration']  as num).toDouble()),
        endLocation: AppLatLng(
            (loc[1] as num).toDouble(), (loc[0] as num).toDouble()),
        maneuver: mv['type'] as String? ?? '',
      ));
    }
    return DirectionsResult(
      polylinePoints: pts,
      steps:          steps,
      totalDistance:  _fmtDist((route['distance'] as num).toDouble()),
      totalDuration:  _fmtDur((route['duration']  as num).toDouble()),
      origin:         o,
      destination:    d,
    );
  }

  // ── Polyline decoder (Google's encoded polyline algorithm) ────────────────
  static List<AppLatLng> _decode(String enc) {
    final pts = <AppLatLng>[];
    int idx = 0, lat = 0, lng = 0;
    while (idx < enc.length) {
      int b, sh = 0, res = 0;
      do {
        b = enc.codeUnitAt(idx++) - 63;
        res |= (b & 0x1f) << sh;
        sh += 5;
      } while (b >= 0x20);
      lat += ((res & 1) != 0) ? ~(res >> 1) : (res >> 1);
      sh = 0; res = 0;
      do {
        b = enc.codeUnitAt(idx++) - 63;
        res |= (b & 0x1f) << sh;
        sh += 5;
      } while (b >= 0x20);
      lng += ((res & 1) != 0) ? ~(res >> 1) : (res >> 1);
      pts.add(AppLatLng(lat / 1e5, lng / 1e5));
    }
    return pts;
  }

  static String _inst(String type, String mod, String name) {
    final on = name.isNotEmpty ? ' onto $name' : '';
    switch (type) {
      case 'depart':     return 'Head${mod.isNotEmpty ? ' $mod' : ''}$on';
      case 'arrive':     return 'You have arrived at your destination';
      case 'turn':       return 'Turn $mod$on';
      case 'merge':      return 'Merge $mod$on';
      case 'fork':       return 'Keep $mod at the fork$on';
      case 'roundabout': return 'Enter the roundabout$on';
      default:           return 'Continue$on';
    }
  }

  static String _fmtDist(double m) =>
      m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.toInt()} m';

  static String _fmtDur(double s) {
    final mins = (s / 60).round();
    if (mins >= 60) {
      final h = mins ~/ 60;
      final m = mins % 60;
      return m > 0 ? '$h hr $m min' : '$h hr';
    }
    return '$mins min';
  }
}
