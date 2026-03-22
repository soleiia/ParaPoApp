import 'package:flutter/material.dart';

class TransportModel {
  final int? id;
  final String name;
  final double fare;
  final bool active;
  final String emoji;

  const TransportModel({this.id, required this.name, required this.fare, required this.active, required this.emoji});

  factory TransportModel.fromMap(Map<String, dynamic> m) => TransportModel(
    id: m['id'] as int?, name: m['name'] as String,
    fare: (m['fare'] as num).toDouble(), active: (m['active'] as int) == 1, emoji: m['emoji'] as String,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'name': name, 'fare': fare, 'active': active ? 1 : 0, 'emoji': emoji,
  };

  TransportModel copyWith({String? name, double? fare, bool? active, String? emoji}) =>
    TransportModel(id: id, name: name ?? this.name, fare: fare ?? this.fare,
      active: active ?? this.active, emoji: emoji ?? this.emoji);
}

class RouteModel {
  final int? id;
  final String origin;
  final String destination;
  final double fare;

  const RouteModel({this.id, required this.origin, required this.destination, required this.fare});

  factory RouteModel.fromMap(Map<String, dynamic> m) => RouteModel(
    id: m['id'] as int?, origin: m['origin'] as String,
    destination: m['destination'] as String, fare: (m['fare'] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'origin': origin, 'destination': destination, 'fare': fare,
  };
}

class TerminalModel {
  final int? id;
  final String category;
  final String name;
  final String description;
  final String emoji;

  const TerminalModel({this.id, required this.category, required this.name, required this.description, required this.emoji});

  factory TerminalModel.fromMap(Map<String, dynamic> m) => TerminalModel(
    id: m['id'] as int?, category: m['category'] as String, name: m['name'] as String,
    description: m['description'] as String, emoji: m['emoji'] as String,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'category': category, 'name': name, 'description': description, 'emoji': emoji,
  };
}

class ZoneModel {
  final int? id;
  final String name;
  final String colorHex;
  final int stopCount;

  const ZoneModel({this.id, required this.name, required this.colorHex, required this.stopCount});

  factory ZoneModel.fromMap(Map<String, dynamic> m) => ZoneModel(
    id: m['id'] as int?, name: m['name'] as String,
    colorHex: m['color_hex'] as String, stopCount: m['stop_count'] as int,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'name': name, 'color_hex': colorHex, 'stop_count': stopCount,
  };

  Color get color => Color(int.parse(colorHex, radix: 16));
}
