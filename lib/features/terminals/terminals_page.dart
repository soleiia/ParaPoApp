import 'package:flutter/material.dart';
import 'package:para_po/core/models/models.dart';
import 'package:para_po/core/repositories/repositories.dart';
import 'package:para_po/core/theme/app_theme.dart';
import 'package:para_po/shared/widgets/widgets.dart';

class TerminalsPage extends StatefulWidget {
  const TerminalsPage({super.key});
  @override
  State<TerminalsPage> createState() => _TerminalsPageState();
}

class _TerminalsPageState extends State<TerminalsPage> {
  final _repo = TerminalRepository();
  List<TerminalModel> _all = [], _filtered = [];
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
        : _all.where((t) =>
            t.name.toLowerCase().contains(_query.toLowerCase()) ||
            t.category.toLowerCase().contains(_query.toLowerCase())).toList();
  }

  void _onSearch(String q) => setState(() { _query = q; _applyFilter(); });

  void _showAddDialog() {
    final catCtrl  = TextEditingController();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String emoji = '📍';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, sd) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add Terminal', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        buildDialogField(catCtrl, 'Category (e.g. LIBRARY)'),
        const SizedBox(height: 10),
        buildDialogField(nameCtrl, 'Name'),
        const SizedBox(height: 10),
        buildDialogField(descCtrl, 'Description'),
        const SizedBox(height: 10),
        Row(children: [
          const Text('Emoji: ', style: TextStyle(color: AppColors.textMid)),
          GestureDetector(onTap: () => _pickEmoji(ctx, (e) => sd(() => emoji = e)),
            child: Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(8)),
              child: Text(emoji, style: const TextStyle(fontSize: 24)))),
        ]),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMid))),
        TextButton(onPressed: () async {
          final name = nameCtrl.text.trim();
          if (name.isNotEmpty) {
            await _repo.add(TerminalModel(category: catCtrl.text.trim().toUpperCase(),
              name: name, description: descCtrl.text.trim(), emoji: emoji));
            if (ctx.mounted) { Navigator.pop(ctx); await _load(); }
          }
        }, child: const Text('Add', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700))),
      ],
    )));
  }

  void _showDetail(TerminalModel item) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SheetHandle(),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.category, style: const TextStyle(color: AppColors.blue, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text(item.name, style: const TextStyle(color: AppColors.textDark, fontSize: 22, fontWeight: FontWeight.w800)),
            ])),
            Text(item.emoji, style: const TextStyle(fontSize: 40)),
          ]),
          const SizedBox(height: 12),
          Text(item.description, style: const TextStyle(color: AppColors.textMid, fontSize: 14, height: 1.5)),
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
          BlueBtn(label: 'Get Directions', onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Directions to ${item.name} opened!'), backgroundColor: AppColors.blue));
          }),
        ]),
      ),
    );
  }

  void _showEditDialog(TerminalModel item) {
    final catCtrl  = TextEditingController(text: item.category);
    final nameCtrl = TextEditingController(text: item.name);
    final descCtrl = TextEditingController(text: item.description);
    String emoji = item.emoji;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, sd) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Edit Terminal', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        buildDialogField(catCtrl, 'Category'),
        const SizedBox(height: 10),
        buildDialogField(nameCtrl, 'Name'),
        const SizedBox(height: 10),
        buildDialogField(descCtrl, 'Description'),
        const SizedBox(height: 10),
        Row(children: [
          const Text('Emoji: ', style: TextStyle(color: AppColors.textMid)),
          GestureDetector(onTap: () => _pickEmoji(ctx, (e) => sd(() => emoji = e)),
            child: Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(8)),
              child: Text(emoji, style: const TextStyle(fontSize: 24)))),
        ]),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMid))),
        TextButton(onPressed: () async {
          await _repo.update(TerminalModel(id: item.id, category: catCtrl.text.trim().toUpperCase(),
            name: nameCtrl.text.trim(), description: descCtrl.text.trim(), emoji: emoji));
          if (ctx.mounted) { Navigator.pop(ctx); await _load(); }
        }, child: const Text('Save', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700))),
      ],
    )));
  }

  void _pickEmoji(BuildContext ctx, ValueChanged<String> onPick) {
    const emojis = ['📍','🏛️','☕','📚','🏢','🏥','🏫','🏦','🛒','🏋️','🎭','🏺','🍽️','⛽','🅿️','🚉'];
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
      PageHeader(title: 'Transportation Terminals', onAdd: _showAddDialog, onSearch: _onSearch),
      Expanded(child: _loading ? const LoadingState() : _filtered.isEmpty ? const EmptyState()
        : RefreshIndicator(color: AppColors.blue, onRefresh: _load,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1, indent: 76, endIndent: 16),
            itemBuilder: (_, i) {
              final t = _filtered[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(width: 52, height: 52,
                  decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider)),
                  child: Center(child: Text(t.emoji, style: const TextStyle(fontSize: 26)))),
                title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.category, style: const TextStyle(color: AppColors.blue, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(t.name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 15)),
                ]),
                subtitle: Padding(padding: const EdgeInsets.only(top: 2),
                  child: Text(t.description, style: const TextStyle(color: AppColors.textMid, fontSize: 13),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                onTap: () => _showDetail(t),
              );
            },
          ))),
    ]);
  }
}
