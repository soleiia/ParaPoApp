import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:para_po/core/database/database_helper.dart';
import 'package:para_po/shared/widgets/passenger_type_selector.dart';
import 'package:para_po/shared/widgets/fare_badge.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  List<Map<String, dynamic>> _routes = [];

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    try {
      // Accessing the singleton instance of your database helper
      final data = await DatabaseHelper.instance.queryAll('routes');
      setState(() {
        _routes = data;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error loading routes: $e");
      }
      // This part is key: if the database is still "rebuilding" on your laptop,
      // it waits 1 second and tries again instead of showing a red error screen.
      await Future.delayed(const Duration(seconds: 1));
      _loadRoutes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routes & Fares')),
      body: Column(
        children: [
          // ── Passenger type selector (full variant) ──
          const PassengerTypeSelector(),

          // ── Routes list ──
          Expanded(
            child: ListView.builder(
              itemCount: _routes.length,
              itemBuilder: (context, index) {
                final route = _routes[index];
                return _RouteCard(route: route);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final Map<String, dynamic> route;

  const _RouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseFare = (route['fare'] as num).toDouble();
    final transportType = route['transport_type'] as String? ?? 'Jeepney';
    final via = route['via'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Transport icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _emojiForTransport(transportType),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Route info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route['origin'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(Icons.arrow_downward,
                          size: 12, color: colorScheme.primary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          route['destination'] as String,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (via.isNotEmpty)
                    Text(
                      'via $via',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Fare badge — reacts to FareProvider automatically
            FareBadge(baseFare: baseFare),
          ],
        ),
      ),
    );
  }

  String _emojiForTransport(String type) {
    if (type.contains('Tricycle')) return '🛺';
    if (type.contains('Modern')) return '🚌';
    if (type.contains('Jeepney')) return '🚙';
    if (type.contains('UV') || type.contains('Van')) return '🚐';
    if (type.contains('Bus')) return '🚍';
    if (type.contains('PNR') || type.contains('Train')) return '🚆';
    return '🚌';
  }
}
