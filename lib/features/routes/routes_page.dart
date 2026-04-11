import 'package:flutter/material.dart';
import 'package:para_po/core/models/models.dart';
import 'package:para_po/core/repositories/repositories.dart';
import 'package:para_po/core/theme/app_theme.dart';
import 'package:para_po/core/app_state.dart';
import 'package:para_po/shared/widgets/widgets.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});
  @override State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final _repo = RouteRepository();
  List<RouteModel> _all = [], _filtered = [];
  bool _loading = true;
  String _query = '';

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _all = await _repo.getAll();
    _applyFilter();
    setState(() => _loading = false);
  }

  void _applyFilter() {
    _filtered = _query.isEmpty ? List.from(_all)
        : _all.where((r) =>
            r.origin.toLowerCase().contains(_query.toLowerCase()) ||
            r.destination.toLowerCase().contains(_query.toLowerCase()) ||
            r.transportType.toLowerCase().contains(_query.toLowerCase())).toList();
  }

  void _onSearch(String q) => setState(() { _query = q; _applyFilter(); });

  // ── Navigate to map with this route ──────────────────────────────────────
  void _openOnMap(RouteModel route) {
    AppState.instance.goToMap(route: route);
  }

  void _showAddDialog() {
    final originCtrl = TextEditingController();
    final destCtrl   = TextEditingController();
    final fareCtrl   = TextEditingController();
    final oLatCtrl   = TextEditingController();
    final oLngCtrl   = TextEditingController();
    final dLatCtrl   = TextEditingController();
    final dLngCtrl   = TextEditingController();
    final distCtrl   = TextEditingController();
    String transport = 'Jeepney';
    const types = ['Jeepney', 'E-Jeepney / Modern Jeepney', 'Tricycle (Within Barangay)',
        'UV Express / FX', 'Bus (Ordinary)', 'Bus (Air-Conditioned)', 'TNVS / Grab Car'];

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, sd) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add Route', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        buildDialogField(originCtrl, 'Origin'),
        const SizedBox(height: 8),
        buildDialogField(destCtrl, 'Destination'),
        const SizedBox(height: 8),
        buildDialogField(fareCtrl, 'Base Fare (Ph)', type: TextInputType.number),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: transport,
          decoration: InputDecoration(filled: true, fillColor: AppColors.offWhite,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          items: types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => sd(() => transport = v!),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: buildDialogField(oLatCtrl, 'Origin Lat', type: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(child: buildDialogField(oLngCtrl, 'Origin Lng', type: TextInputType.number)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: buildDialogField(dLatCtrl, 'Dest Lat', type: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(child: buildDialogField(dLngCtrl, 'Dest Lng', type: TextInputType.number)),
        ]),
        const SizedBox(height: 8),
        buildDialogField(distCtrl, 'Distance (km)', type: TextInputType.number),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMid))),
        TextButton(onPressed: () async {
          final origin = originCtrl.text.trim();
          final dest   = destCtrl.text.trim();
          final fare   = double.tryParse(fareCtrl.text) ?? 0;
          if (origin.isNotEmpty && dest.isNotEmpty) {
            await _repo.add(RouteModel(
              origin: origin, destination: dest, fare: fare,
              originLat: double.tryParse(oLatCtrl.text) ?? 14.2724,
              originLng: double.tryParse(oLngCtrl.text) ?? 121.1241,
              destLat:   double.tryParse(dLatCtrl.text) ?? 14.2724,
              destLng:   double.tryParse(dLngCtrl.text) ?? 121.1241,
              transportType: transport,
              distanceKm: double.tryParse(distCtrl.text) ?? 0,
            ));
            if (ctx.mounted) { Navigator.pop(ctx); await _load(); }
          }
        }, child: const Text('Add', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700))),
      ],
    )));
  }

  void _showDetail(RouteModel item) {
    showModalBottomSheet(context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SheetHandle(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('FROM', style: TextStyle(color: AppColors.textLight, fontSize: 11, letterSpacing: 1)),
              Text(item.origin, style: const TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w800)),
            ]),
            Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward, color: AppColors.blue)),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('TO', style: TextStyle(color: AppColors.textLight, fontSize: 11, letterSpacing: 1)),
              Text(item.destination, style: const TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w800)),
            ]),
          ]),
          const SizedBox(height: 16),
          Container(width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Transport Type', style: TextStyle(color: AppColors.textMid, fontSize: 13)),
                Text(item.transportType, style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
              if (item.distanceKm > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Distance', style: TextStyle(color: AppColors.textMid, fontSize: 13)),
                Text('${item.distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
              if (item.distanceKm > 0) const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Regular Fare', style: TextStyle(color: AppColors.textMid, fontSize: 13)),
                Text('Ph${item.fare.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Discounted (20% off)', style: TextStyle(color: AppColors.textMid, fontSize: 13)),
                Text('Ph${item.fareFor(true).toStringAsFixed(2)}',
                    style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 15, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 12),
              const FareToggle(),
            ])),
          const SizedBox(height: 12),
          // Edit / Delete
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Edit'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.blue,
                  side: const BorderSide(color: AppColors.blue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () { Navigator.pop(context); _showEditDialog(item); })),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline, size: 16), label: const Text('Delete'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.red,
                  side: const BorderSide(color: AppColors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                Navigator.pop(context);
                final confirm = await showDeleteDialog(context, '${item.origin} → ${item.destination}');
                if (confirm == true) { await _repo.delete(item.id!); await _load(); }
              })),
          ]),
          const SizedBox(height: 12),
          // View on Map button
          BlueBtn(label: '🗺️  View on Map', onTap: () {
            Navigator.pop(context);
            _openOnMap(item);
          }),
        ]),
      ),
    );
  }

  void _showEditDialog(RouteModel item) {
    final originCtrl = TextEditingController(text: item.origin);
    final destCtrl   = TextEditingController(text: item.destination);
    final fareCtrl   = TextEditingController(text: item.fare.toString());
    final oLatCtrl   = TextEditingController(text: item.originLat.toString());
    final oLngCtrl   = TextEditingController(text: item.originLng.toString());
    final dLatCtrl   = TextEditingController(text: item.destLat.toString());
    final dLngCtrl   = TextEditingController(text: item.destLng.toString());
    final distCtrl   = TextEditingController(text: item.distanceKm.toString());
    String transport = item.transportType;
    const types = ['Jeepney', 'E-Jeepney / Modern Jeepney', 'Tricycle (Within Barangay)',
        'UV Express / FX', 'Bus (Ordinary)', 'Bus (Air-Conditioned)', 'TNVS / Grab Car'];

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, sd) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Edit Route', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        buildDialogField(originCtrl, 'Origin'),
        const SizedBox(height: 8),
        buildDialogField(destCtrl, 'Destination'),
        const SizedBox(height: 8),
        buildDialogField(fareCtrl, 'Base Fare', type: TextInputType.number),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: types.contains(transport) ? transport : types.first,
          decoration: InputDecoration(filled: true, fillColor: AppColors.offWhite,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          items: types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => sd(() => transport = v!),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: buildDialogField(oLatCtrl, 'Origin Lat', type: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(child: buildDialogField(oLngCtrl, 'Origin Lng', type: TextInputType.number)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: buildDialogField(dLatCtrl, 'Dest Lat', type: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(child: buildDialogField(dLngCtrl, 'Dest Lng', type: TextInputType.number)),
        ]),
        const SizedBox(height: 8),
        buildDialogField(distCtrl, 'Distance (km)', type: TextInputType.number),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMid))),
        TextButton(onPressed: () async {
          await _repo.update(RouteModel(
            id: item.id, origin: originCtrl.text.trim(), destination: destCtrl.text.trim(),
            fare: double.tryParse(fareCtrl.text) ?? item.fare,
            originLat: double.tryParse(oLatCtrl.text) ?? item.originLat,
            originLng: double.tryParse(oLngCtrl.text) ?? item.originLng,
            destLat:   double.tryParse(dLatCtrl.text) ?? item.destLat,
            destLng:   double.tryParse(dLngCtrl.text) ?? item.destLng,
            transportType: transport,
            distanceKm: double.tryParse(distCtrl.text) ?? item.distanceKm,
          ));
          if (ctx.mounted) { Navigator.pop(ctx); await _load(); }
        }, child: const Text('Save', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700))),
      ],
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PageHeader(title: 'Available Routes', onAdd: _showAddDialog, onSearch: _onSearch,
        extraActions: [const FareToggle(), const SizedBox(width: 8)]),
      Expanded(child: _loading ? const LoadingState() : _filtered.isEmpty ? const EmptyState()
        : RefreshIndicator(color: AppColors.blue, onRefresh: _load,
          child: ListView.separated(padding: EdgeInsets.zero, itemCount: _filtered.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1, indent: 16, endIndent: 16),
            itemBuilder: (_, i) {
              final r = _filtered[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FareDisplay(fare: r.fare, compact: true),
                  const SizedBox(height: 2),
                  Text(r.origin, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 16)),
                ]),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.destination, style: const TextStyle(color: AppColors.textMid, fontSize: 14)),
                  Text(r.transportType, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                ]),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  // Quick map button
                  GestureDetector(
                    onTap: () => _openOnMap(r),
                    child: Container(padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.map_outlined, color: AppColors.blue, size: 18)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: AppColors.textLight),
                ]),
                onTap: () => _showDetail(r),
              );
            }))),
    ]);
  }
}
