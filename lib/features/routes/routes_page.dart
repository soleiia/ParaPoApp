import 'package:flutter/material.dart';
import 'package:para_po/core/models/models.dart';
import 'package:para_po/core/repositories/repositories.dart';
import 'package:para_po/core/theme/app_theme.dart';
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
  String _query = '';

  @override
  void initState() { super.initState(); _load(); }

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
            r.destination.toLowerCase().contains(_query.toLowerCase())).toList();
  }

  void _onSearch(String q) => setState(() { _query = q; _applyFilter(); });

  void _showAddDialog() {
    final originCtrl = TextEditingController();
    final destCtrl   = TextEditingController();
    final fareCtrl   = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add Route', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        buildDialogField(originCtrl, 'Origin'),
        const SizedBox(height: 10),
        buildDialogField(destCtrl, 'Destination'),
        const SizedBox(height: 10),
        buildDialogField(fareCtrl, 'Fare (₱)', type: TextInputType.number),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMid))),
        TextButton(onPressed: () async {
          final origin = originCtrl.text.trim();
          final dest   = destCtrl.text.trim();
          final fare   = double.tryParse(fareCtrl.text) ?? 0;
          if (origin.isNotEmpty && dest.isNotEmpty) {
            await _repo.add(RouteModel(origin: origin, destination: dest, fare: fare));
            if (ctx.mounted) { Navigator.pop(ctx); await _load(); }
          }
        }, child: const Text('Add', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700))),
      ],
    ));
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
              Text(item.origin, style: const TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
            Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward, color: AppColors.blue)),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('TO', style: TextStyle(color: AppColors.textLight, fontSize: 11, letterSpacing: 1)),
              Text(item.destination, style: const TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
          ]),
          const SizedBox(height: 16),
          Container(width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Fare', style: TextStyle(color: AppColors.textMid, fontSize: 14)),
              Text('₱${item.fare.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w800, fontSize: 20)),
            ])),
          const SizedBox(height: 12),
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
          BlueBtn(label: 'Select This Route', onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${item.origin} → ${item.destination} selected!'), backgroundColor: AppColors.blue));
          }),
        ]),
      ),
    );
  }

  void _showEditDialog(RouteModel item) {
    final originCtrl = TextEditingController(text: item.origin);
    final destCtrl   = TextEditingController(text: item.destination);
    final fareCtrl   = TextEditingController(text: item.fare.toString());
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Edit Route', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        buildDialogField(originCtrl, 'Origin'),
        const SizedBox(height: 10),
        buildDialogField(destCtrl, 'Destination'),
        const SizedBox(height: 10),
        buildDialogField(fareCtrl, 'Fare (₱)', type: TextInputType.number),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMid))),
        TextButton(onPressed: () async {
          await _repo.update(RouteModel(id: item.id, origin: originCtrl.text.trim(),
            destination: destCtrl.text.trim(), fare: double.tryParse(fareCtrl.text) ?? item.fare));
          if (ctx.mounted) { Navigator.pop(ctx); await _load(); }
        }, child: const Text('Save', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PageHeader(title: 'Available Routes', onAdd: _showAddDialog, onSearch: _onSearch),
      Expanded(child: _loading ? const LoadingState() : _filtered.isEmpty ? const EmptyState()
        : RefreshIndicator(color: AppColors.blue, onRefresh: _load,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1, indent: 16, endIndent: 16),
            itemBuilder: (_, i) {
              final r = _filtered[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('₱${r.fare.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.blue, fontSize: 11, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(r.origin, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 16)),
                ]),
                subtitle: Padding(padding: const EdgeInsets.only(top: 2),
                  child: Text(r.destination, style: const TextStyle(color: AppColors.textMid, fontSize: 14))),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                onTap: () => _showDetail(r),
              );
            },
          ))),
    ]);
  }
}
