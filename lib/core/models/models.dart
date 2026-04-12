import 'package:flutter/material.dart';

// ── AppLatLng ─────────────────────────────────────────────────────────────────
class AppLatLng {
  final double lat;
  final double lng;
  const AppLatLng(this.lat, this.lng);
  @override String toString() => '($lat, $lng)';
}

// ── DirectionStep ─────────────────────────────────────────────────────────────
class DirectionStep {
  final String instruction;
  final String distance;
  final String duration;
  final AppLatLng endLocation;
  final String maneuver;

  const DirectionStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.endLocation,
    this.maneuver = '',
  });
}

// ── DirectionsResult ──────────────────────────────────────────────────────────
class DirectionsResult {
  final List<AppLatLng> polylinePoints;
  final List<DirectionStep> steps;
  final String totalDistance;
  final String totalDuration;
  final AppLatLng origin;
  final AppLatLng destination;

  const DirectionsResult({
    required this.polylinePoints,
    required this.steps,
    required this.totalDistance,
    required this.totalDuration,
    required this.origin,
    required this.destination,
  });
}

// ── TransportModel ────────────────────────────────────────────────────────────
// 4 types: Tricycle, E-Tricycle, Jeepney (Traditional), Jeepney (Modern)
class TransportModel {
  final int?   id;
  final String name;
  final double fare;
  final bool   active;
  final String emoji;

  const TransportModel({
    this.id,
    required this.name,
    required this.fare,
    required this.active,
    required this.emoji,
  });

  /// Returns fare after applying 20% LTFRB discount if [discounted] is true.
  double fareFor(bool discounted) =>
      discounted ? (fare * 0.80) : fare;

  factory TransportModel.fromMap(Map<String, dynamic> m) => TransportModel(
    id:     m['id']     as int?,
    name:   m['name']   as String,
    fare:   (m['fare']  as num).toDouble(),
    active: (m['active'] as int) == 1,
    emoji:  m['emoji']  as String,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name':   name,
    'fare':   fare,
    'active': active ? 1 : 0,
    'emoji':  emoji,
  };

  TransportModel copyWith({
    String? name, double? fare, bool? active, String? emoji,
  }) => TransportModel(
    id:     id,
    name:   name   ?? this.name,
    fare:   fare   ?? this.fare,
    active: active ?? this.active,
    emoji:  emoji  ?? this.emoji,
  );
}

// ── RouteModel ────────────────────────────────────────────────────────────────
class RouteModel {
  final int?   id;
  final String transportType;
  final String origin;
  final String destination;
  final double fare;
  final String via; // route description / road taken

  const RouteModel({
    this.id,
    this.transportType = 'Jeepney (Traditional)',
    required this.origin,
    required this.destination,
    required this.fare,
    this.via = '',
  });

  /// Returns fare after applying 20% LTFRB discount if [discounted] is true.
  double fareFor(bool discounted) =>
      discounted ? (fare * 0.80) : fare;

  factory RouteModel.fromMap(Map<String, dynamic> m) => RouteModel(
    id:            m['id']             as int?,
    transportType: m['transport_type'] as String? ?? 'Jeepney (Traditional)',
    origin:        m['origin']         as String,
    destination:   m['destination']    as String,
    fare:          (m['fare']          as num).toDouble(),
    via:           m['via']            as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'transport_type': transportType,
    'origin':         origin,
    'destination':    destination,
    'fare':           fare,
    'via':            via,
  };
}

// ── TerminalModel ─────────────────────────────────────────────────────────────
class TerminalModel {
  final int?   id;
  final String category;
  final String name;
  final String description;
  final String emoji;

  const TerminalModel({
    this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.emoji,
  });

  factory TerminalModel.fromMap(Map<String, dynamic> m) => TerminalModel(
    id:          m['id']          as int?,
    category:    m['category']    as String,
    name:        m['name']        as String,
    description: m['description'] as String,
    emoji:       m['emoji']       as String,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'category':    category,
    'name':        name,
    'description': description,
    'emoji':       emoji,
  };
}

// ── ZoneModel ─────────────────────────────────────────────────────────────────
class ZoneModel {
  final int?   id;
  final String name;
  final String colorHex;
  final int    stopCount;

  const ZoneModel({
    this.id,
    required this.name,
    required this.colorHex,
    required this.stopCount,
  });

  factory ZoneModel.fromMap(Map<String, dynamic> m) => ZoneModel(
    id:        m['id']         as int?,
    name:      m['name']       as String,
    colorHex:  m['color_hex']  as String,
    stopCount: m['stop_count'] as int,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name':       name,
    'color_hex':  colorHex,
    'stop_count': stopCount,
  };

  Color get color => Color(int.parse(colorHex, radix: 16));
}
