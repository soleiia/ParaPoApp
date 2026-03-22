import 'package:flutter/material.dart';
import 'package:para_po/core/models/models.dart';
import 'package:para_po/core/repositories/repositories.dart';
import 'package:para_po/core/theme/app_theme.dart';
import 'package:para_po/shared/widgets/widgets.dart';

class TransportationPage extends StatefulWidget {
  const TransportationPage({super.key});
  @override
  State<TransportationPage> createState() => _TransportationPageState();
}

class _TransportationPageState extends State<TransportationPage> {
  final _repo = TransportRepository();
  List<TransportModel> _all = [], _filtered = [];
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
    _filtered = _query.isEmpty
        ? List.from(_all)
        : _all.where((t) => t.name.toLowerCase().contains(_query.toLowerCase())).toList();
  }

  void _onSearch(String q) => setState(() { _query = q; _applyFilter(); });

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final fareCtrl = TextEditingController();
    bool active = true;
    String emoji = '🚌';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, sd) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Transportation', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          buildDialogField(nameCtrl, 'Name'),
          const SizedBox(height: 10),
          buildDialogField(fareCtrl, 'Fare (₱)', type: TextInputType.number),
          const SizedBox(height: 10),
          Row(children: [
            const Text('Emoji: ', style: TextStyle(color: AppColors.textMid)),
            GestureDetector(onTap: () => _pickEmoji(ctx, (e) => sd(() => emoji = e)),
              child: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(8)),
                child: Text(emoji, style: const TextStyle(fontSize: 24)))),
            const Spacer(),
            const Text('Active: ', style: TextStyle(color: AppColors.textMid)),
            Switch(value: active, activeThumbColor: AppColors.blue, onChanged: (v) => sd(() => active = v)),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMid))),
          TextButton(onPressed: () async {
            final name = nameCtrl.text.trim();
            final fare = double.tryParse(fareCtrl.text) ?? 0;
            if (name.isNotEmpty) {
              await _repo.add(TransportModel(name: name, fare: fare, active: active, emoji: emoji));
              if (ctx.mounted) { Navigator.pop(ctx); await _load(); }
            }
          }, child: const Text('Add', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700))),
        ],
      )),
    );
  }

  void _showDetail(TransportModel item) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SheetHandle(),
          Row(children: [
            Text(item.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 4),
              StatusBadge(active: item.active),
            ])),
            IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.blue),
              onPressed: () { Navigator.pop(context); _showEditDialog(item); }),
            IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.red),
              onPressed: () async {
                Navigator.pop(context);
                final confirm = await showDeleteDialog(context, item.name);
                if (confirm == true) { await _repo.delete(item.id!); await _load(); }
              }),
          ]),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              DetailRow('Fare', '₱${item.fare.toStringAsFixed(2)}'),
              const Divider(color: AppColors.divider),
              DetailRow('Status', item.active ? 'Active' : 'Inactive'),
            ])),
          const SizedBox(height: 20),
          BlueBtn(label: 'Select This Transport', onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${item.name} selected!'), backgroundColor: AppColors.blue));
          }),
        ]),
      ),
    );
  }

  void _showEditDialog(TransportModel item) {
    final nameCtrl = TextEditingController(text: item.name);
    final fareCtrl = TextEditingController(text: item.fare.toString());
    bool active = item.active;
    String emoji = item.emoji;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, sd) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Transportation', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          buildDialogField(nameCtrl, 'Name'),
          const SizedBox(height: 10),
          buildDialogField(fareCtrl, 'Fare (₱)', type: TextInputType.number),
          const SizedBox(height: 10),
          Row(children: [
            const Text('Emoji: ', style: TextStyle(color: AppColors.textMid)),
            GestureDetector(onTap: () => _pickEmoji(ctx, (e) => sd(() => emoji = e)),
              child: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(8)),
                child: Text(emoji, style: const TextStyle(fontSize: 24)))),
            const Spacer(),
            const Text('Active: ', style: TextStyle(color: AppColors.textMid)),
            Switch(value: active, activeThumbColor: AppColors.blue, onChanged: (v) => sd(() => active = v)),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMid))),
          TextButton(onPressed: () async {
            await _repo.update(item.copyWith(
              name: nameCtrl.text.trim(), fare: double.tryParse(fareCtrl.text) ?? item.fare,
              active: active, emoji: emoji));
            if (ctx.mounted) { Navigator.pop(ctx); await _load(); }
          }, child: const Text('Save', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700))),
        ],
      )),
    );
  }

  void _pickEmoji(BuildContext ctx, ValueChanged<String> onPick) {
    const emojis = ['🚌','🚍','🚎','🚇','🚊','🚋','🚃','🚂','⛴️','🚢','🚁','🚲','🛴','🚗','🚕','🏍️','🛺'];
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Pick Emoji'),
      content: Wrap(spacing: 10, runSpacing: 10, children: emojis.map((e) =>
        GestureDetector(onTap: () { onPick(e); Navigator.pop(ctx); },
          child: Text(e, style: const TextStyle(fontSize: 30)))).toList()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PageHeader(
        title: 'Transportation Options',
        onAdd: _showAddDialog,
        onSearch: _onSearch,
        extraActions: [
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Filter applied'), backgroundColor: AppColors.blue)),
            child: Container(width: 36, height: 36, margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.tune, color: Colors.white, size: 18)),
          ),
        ],
      ),
      Expanded(child: _loading ? const LoadingState() : _filtered.isEmpty ? const EmptyState()
        : RefreshIndicator(color: AppColors.blue, onRefresh: _load,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1, indent: 76, endIndent: 16),
            itemBuilder: (_, i) => _TransportTile(item: _filtered[i], onTap: () => _showDetail(_filtered[i])),
          ))),
    ]);
  }
}

class _TransportTile extends StatelessWidget {
  final TransportModel item;
  final VoidCallback onTap;
  const _TransportTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    leading: Container(width: 52, height: 52,
      decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider)),
      child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 26)))),
    title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      StatusBadge(active: item.active),
      const SizedBox(height: 2),
      Text(item.name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 15)),
    ]),
    subtitle: Padding(padding: const EdgeInsets.only(top: 2),
      child: Text('₱${item.fare.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textMid, fontSize: 13))),
    trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
  );
}
