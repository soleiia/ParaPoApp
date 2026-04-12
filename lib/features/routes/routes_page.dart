import 'package:flutter/material.dart';
import 'package:para_po/core/models/models.dart';
import 'package:para_po/core/repositories/repositories.dart';
import 'package:para_po/core/theme/app_theme.dart';
import 'package:para_po/core/app_state.dart';
import 'package:para_po/shared/widgets/widgets.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});
  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final _repo = RouteRepository();
  List<RouteModel> _all = [], _filtered = [];
  bool _loading = true;
  String _query      = '';
  String _filterType = 'All';

  static const _types = [
    'All',
    'Tricycle',
    'E-Tricycle',
    'Jeepney (Traditional)',
    'Jeepney (Modern)',
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _all = await _repo.getAll();
    _applyFilter();
    setState(() => _loading = false);
  }

  void _applyFilter() {
    var list = List<RouteModel>.from(_all);
    if (_filterType != 'All') {
      list = list.where((r) => r.transportType == _filterType).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((r) =>
          r.origin.toLowerCase().contains(q) ||
          r.destination.toLowerCase().contains(q) ||
          r.via.toLowerCase().contains(q)).toList();
    }
    _filtered = list;
  }

  void _onSearch(String q) => setState(() { _query = q; _applyFilter(); });

  void _openOnMap(RouteModel route) => AppState.instance.goToMap(route: route);

  void _showAddDialog() {
    final originCtrl = TextEditingController();
    final destCtrl   = TextEditingController();
    final fareCtrl   = TextEditingController();
    final viaCtrl    = TextEditingController();
    String transport = 'Jeepney (Traditional)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, sd) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Route', style: TextStyle(
              fontWeight: FontWeight.w800, color: AppColors.textDark)),
          content: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min, children: [
            buildDialogField(originCtrl, 'Origin'),
            const SizedBox(height: 8),
            buildDialogField(destCtrl, 'Destination'),
            const SizedBox(height: 8),
            buildDialogField(fareCtrl, 'Base Fare (₱)',
                type: TextInputType.number),
            const SizedBox(height: 8),
            buildDialogField(viaCtrl, 'Via (road / highway)'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: transport,
              decoration: InputDecoration(
                filled: true, fillColor: AppColors.offWhite,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none)),
              items: _types.skip(1).map((t) =>
                  DropdownMenuItem(value: t,
                      child: Text(t, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => sd(() => transport = v!),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textMid))),
            TextButton(
              onPressed: () async {
                final origin = originCtrl.text.trim();
                final dest   = destCtrl.text.trim();
                final fare   = double.tryParse(fareCtrl.text) ?? 0;
                if (origin.isNotEmpty && dest.isNotEmpty) {
                  await _repo.add(RouteModel(
                      origin:        origin,
                      destination:   dest,
                      fare:          fare,
                      via:           viaCtrl.text.trim(),
                      transportType: transport));
                  if (ctx.mounted) { Navigator.pop(ctx); await _load(); }
                }
              },
              child: const Text('Add', style: TextStyle(
                  color: AppColors.blue, fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }

  void _showDetail(RouteModel item) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SheetHandle(),
          // Transport type badge
          Align(alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(item.transportType, style: const TextStyle(
                  color: AppColors.blue, fontSize: 12,
                  fontWeight: FontWeight.w700)))),
          const SizedBox(height: 12),
          // Origin → Destination
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('FROM', style: TextStyle(color: AppColors.textLight,
                  fontSize: 11, letterSpacing: 1)),
              Text(item.origin, style: const TextStyle(color: AppColors.textDark,
                  fontSize: 16, fontWeight: FontWeight.w800)),
            ])),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward, color: AppColors.blue)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end,
                children: [
              const Text('TO', style: TextStyle(color: AppColors.textLight,
                  fontSize: 11, letterSpacing: 1)),
              Text(item.destination, style: const TextStyle(
                  color: AppColors.textDark, fontSize: 16,
                  fontWeight: FontWeight.w800), textAlign: TextAlign.end),
            ])),
          ]),
          const SizedBox(height: 12),
          if (item.via.isNotEmpty)
            Row(children: [
              const Icon(Icons.alt_route, color: AppColors.textLight, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text('via ${item.via}', style: const TextStyle(
                  color: AppColors.textMid, fontSize: 12),
                  overflow: TextOverflow.ellipsis)),
            ]),
          const SizedBox(height: 12),
          // Fare box
          Container(width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Regular Fare',
                    style: TextStyle(color: AppColors.textMid, fontSize: 13)),
                Text('₱${item.fare.toStringAsFixed(2)}', style: const TextStyle(
                    color: AppColors.textDark, fontSize: 15,
                    fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Discounted (20% off)',
                    style: TextStyle(color: AppColors.textMid, fontSize: 13)),
                Text('₱${item.fareFor(true).toStringAsFixed(2)}',
                    style: const TextStyle(color: Color(0xFF2E7D32),
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ]),
              const Divider(color: AppColors.divider, height: 20),
              const FareToggle(),
            ])),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.blue,
                  side: const BorderSide(color: AppColors.blue),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () { Navigator.pop(context); _showEditDialog(item); })),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Delete'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.red,
                  side: const BorderSide(color: AppColors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                Navigator.pop(context);
                final ok = await showDeleteDialog(context,
                    '${item.origin} → ${item.destination}');
                if (ok == true) { await _repo.delete(item.id!); await _load(); }
              })),
          ]),
          const SizedBox(height: 12),
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
    final viaCtrl    = TextEditingController(text: item.via);
    String transport = _types.skip(1).contains(item.transportType)
        ? item.transportType : _types[1];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, sd) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Route', style: TextStyle(
              fontWeight: FontWeight.w800, color: AppColors.textDark)),
          content: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min, children: [
            buildDialogField(originCtrl, 'Origin'),
            const SizedBox(height: 8),
            buildDialogField(destCtrl, 'Destination'),
            const SizedBox(height: 8),
            buildDialogField(fareCtrl, 'Base Fare (₱)',
                type: TextInputType.number),
            const SizedBox(height: 8),
            buildDialogField(viaCtrl, 'Via (road / highway)'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: transport,
              decoration: InputDecoration(
                filled: true, fillColor: AppColors.offWhite,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none)),
              items: _types.skip(1).map((t) =>
                  DropdownMenuItem(value: t,
                      child: Text(t, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => sd(() => transport = v!),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textMid))),
            TextButton(
              onPressed: () async {
                await _repo.update(RouteModel(
                  id:            item.id,
                  origin:        originCtrl.text.trim(),
                  destination:   destCtrl.text.trim(),
                  fare:          double.tryParse(fareCtrl.text) ?? item.fare,
                  via:           viaCtrl.text.trim(),
                  transportType: transport,
                ));
                if (ctx.mounted) { Navigator.pop(ctx); await _load(); }
              },
              child: const Text('Save', style: TextStyle(
                  color: AppColors.blue, fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PageHeader(title: 'Available Routes', onAdd: _showAddDialog,
          onSearch: _onSearch),
      const PassengerTypeSelector(),
      // Transport type filter chips
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Row(children: _types.map((t) {
          final sel = _filterType == t;
          return GestureDetector(
            onTap: () => setState(() { _filterType = t; _applyFilter(); }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? AppColors.blue : AppColors.offWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? AppColors.blue : AppColors.lightGrey)),
              child: Text(t, style: TextStyle(
                  color: sel ? Colors.white : AppColors.textMid,
                  fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          );
        }).toList()),
      ),
      Expanded(
        child: _loading
            ? const LoadingState()
            : _filtered.isEmpty
                ? const EmptyState()
                : RefreshIndicator(
                    color: AppColors.blue, onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(top: 4),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const Divider(
                          color: AppColors.divider, height: 1,
                          indent: 16, endIndent: 16),
                      itemBuilder: (_, i) {
                        final r = _filtered[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          title: Row(children: [
                            Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              FareDisplay(fare: r.fare, compact: true),
                              const SizedBox(height: 2),
                              Text(r.origin, style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                            ])),
                          ]),
                          subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(r.destination, style: const TextStyle(
                                color: AppColors.textMid, fontSize: 13)),
                            if (r.via.isNotEmpty)
                              Text('via ${r.via}', style: const TextStyle(
                                  color: AppColors.textLight, fontSize: 11),
                                  overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(r.transportType, style: const TextStyle(
                                color: AppColors.blue, fontSize: 11,
                                fontWeight: FontWeight.w600)),
                          ]),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            GestureDetector(
                              onTap: () => _openOnMap(r),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                    color: AppColors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.map_outlined,
                                    color: AppColors.blue, size: 16))),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right,
                                color: AppColors.textLight),
                          ]),
                          onTap: () => _showDetail(r),
                        );
                      },
                    ),
                  ),
      ),
    ]);
  }
}
