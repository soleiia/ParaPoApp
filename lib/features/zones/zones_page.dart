import 'package:flutter/material.dart';
import 'package:para_po/core/models/models.dart';
import 'package:para_po/core/repositories/repositories.dart';
import 'package:para_po/core/theme/app_theme.dart';
import 'package:para_po/shared/widgets/widgets.dart';

class ZonesPage extends StatefulWidget {
  const ZonesPage({super.key});
  @override
  State<ZonesPage> createState() => _ZonesPageState();
}

class _ZonesPageState extends State<ZonesPage> {
  final _repo = ZoneRepository();
  List<ZoneModel> _zones = [];
  bool _loading = true;

  static const _colorOptions = {
    'Blue':   'FF3B6FE0',
    'Green':  'FF43A047',
    'Red':    'FFE53935',
    'Yellow': 'FFFFC200',
    'Purple': 'FF8E24AA',
    'Teal':   'FF00897B',
    'Orange': 'FFEF6C00',
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _zones = await _repo.getAll();
    setState(() => _loading = false);
  }

  void _showAddDialog() {
    final nameCtrl      = TextEditingController();
    final stopCountCtrl = TextEditingController(text: '0');
    String selectedHex  = 'FF3B6FE0';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, sd) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add Zone', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        buildDialogField(nameCtrl, 'Zone Name'),
        const SizedBox(height: 10),
        buildDialogField(stopCountCtrl, 'Number of Stops', type: TextInputType.number),
        const SizedBox(height: 12),
        const Align(alignment: Alignment.centerLeft,
          child: Text('Zone Color', style: TextStyle(color: AppColors.textMid, fontSize: 13, fontWeight: FontWeight.w600))),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _colorOptions.entries.map((e) {
          final color    = Color(int.parse(e.value, radix: 16));
          final selected = selectedHex == e.value;
          return GestureDetector(onTap: () => sd(() => selectedHex = e.value),
            child: Container(width: 32, height: 32, decoration: BoxDecoration(
              color: color, shape: BoxShape.circle,
              border: selected ? Border.all(color: AppColors.textDark, width: 2.5) : null,
              boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)] : null,
            )));
        }).toList()),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMid))),
        TextButton(onPressed: () async {
          final name = nameCtrl.text.trim();
          if (name.isNotEmpty) {
            await _repo.add(ZoneModel(name: name, colorHex: selectedHex,
              stopCount: int.tryParse(stopCountCtrl.text) ?? 0));
            if (ctx.mounted) { Navigator.pop(ctx); await _load(); }
          }
        }, child: const Text('Add', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700))),
      ],
    )));
  }

  void _showDetail(ZoneModel item) {
    showModalBottomSheet(context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SheetHandle(),
          Row(children: [
            Container(width: 18, height: 18, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: item.color.withValues(alpha: 0.4), blurRadius: 8)])),
            const SizedBox(width: 12),
            Text(item.name, style: const TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 16),
          Container(width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              DetailRow('Zone Name', item.name),
              const Divider(color: AppColors.divider),
              DetailRow('Total Stops', '${item.stopCount}'),
            ])),
          const SizedBox(height: 16),
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
                final confirm = await showDeleteDialog(context, item.name);
                if (confirm == true) { await _repo.delete(item.id!); await _load(); }
              })),
          ]),
          const SizedBox(height: 12),
          BlueBtn(label: 'View Zone on Map', onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${item.name} shown on map!'), backgroundColor: AppColors.blue));
          }),
        ]),
      ),
    );
  }

  void _showEditDialog(ZoneModel item) {
    final nameCtrl      = TextEditingController(text: item.name);
    final stopCountCtrl = TextEditingController(text: item.stopCount.toString());
    String selectedHex  = item.colorHex;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, sd) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Edit Zone', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        buildDialogField(nameCtrl, 'Zone Name'),
        const SizedBox(height: 10),
        buildDialogField(stopCountCtrl, 'Number of Stops', type: TextInputType.number),
        const SizedBox(height: 12),
        const Align(alignment: Alignment.centerLeft,
          child: Text('Zone Color', style: TextStyle(color: AppColors.textMid, fontSize: 13, fontWeight: FontWeight.w600))),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _colorOptions.entries.map((e) {
          final color    = Color(int.parse(e.value, radix: 16));
          final selected = selectedHex == e.value;
          return GestureDetector(onTap: () => sd(() => selectedHex = e.value),
            child: Container(width: 32, height: 32, decoration: BoxDecoration(
              color: color, shape: BoxShape.circle,
              border: selected ? Border.all(color: AppColors.textDark, width: 2.5) : null,
            )));
        }).toList()),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMid))),
        TextButton(onPressed: () async {
          await _repo.update(ZoneModel(id: item.id, name: nameCtrl.text.trim(),
            colorHex: selectedHex, stopCount: int.tryParse(stopCountCtrl.text) ?? item.stopCount));
          if (ctx.mounted) { Navigator.pop(ctx); await _load(); }
        }, child: const Text('Save', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700))),
      ],
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PageHeader(title: 'Zones', onAdd: _showAddDialog, onSearch: (_) {}),
      Expanded(child: _loading ? const LoadingState() : _zones.isEmpty
        ? const EmptyState(message: 'No zones yet')
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Summary card
              Container(width: double.infinity, padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.blueDark, AppColors.blue],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20)),
                child: Stack(children: [
                  const Positioned(right: -10, bottom: -20, child: Opacity(opacity: 0.15,
                    child: SizedBox(width: 120, height: 120, child: CustomPaint(painter: SunPainter())))),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Total Zones', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('${_zones.length}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${_zones.fold(0, (s, z) => s + z.stopCount)} total stops',
                      style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ]),
                ])),
              const SizedBox(height: 16),
              // Zone list
              Expanded(child: RefreshIndicator(color: AppColors.blue, onRefresh: _load,
                child: ListView.separated(
                  itemCount: _zones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final z = _zones[i];
                    return GestureDetector(onTap: () => _showDetail(z),
                      child: Container(padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                        child: Row(children: [
                          Container(width: 14, height: 14, decoration: BoxDecoration(color: z.color, shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: z.color.withValues(alpha: 0.4), blurRadius: 6)])),
                          const SizedBox(width: 14),
                          Expanded(child: Text(z.name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 15))),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: z.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                            child: Text('${z.stopCount} stops', style: TextStyle(color: z.color, fontSize: 12, fontWeight: FontWeight.w700))),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right, color: AppColors.textLight, size: 18),
                        ]),
                      ));
                  },
                ))),
            ]),
          )),
    ]);
  }
}
