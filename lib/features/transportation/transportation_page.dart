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

  // The 4 allowed transport types
  static const _allowedTypes = [
    ('Tricycle',              '🛺'),
    ('E-Tricycle',            '🛵'),
    ('Jeepney (Traditional)', '🚙'),
    ('Jeepney (Modern)',      '🚌'),
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
    _filtered = _query.isEmpty
        ? List.from(_all)
        : _all.where((t) =>
            t.name.toLowerCase().contains(_query.toLowerCase())).toList();
  }

  void _onSearch(String q) => setState(() { _query = q; _applyFilter(); });

  void _showAddDialog() {
    final fareCtrl = TextEditingController();
    String selectedName  = _allowedTypes[0].$1;
    String selectedEmoji = _allowedTypes[0].$2;
    bool   active        = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, sd) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Transportation',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            // Type picker (only the 4 allowed)
            const Align(alignment: Alignment.centerLeft,
                child: Text('Type', style: TextStyle(color: AppColors.textMid, fontSize: 13, fontWeight: FontWeight.w600))),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8,
              children: _allowedTypes.map((t) {
                final sel = selectedName == t.$1;
                return GestureDetector(
                  onTap: () => sd(() { selectedName = t.$1; selectedEmoji = t.$2; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.blue : AppColors.offWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? AppColors.blue : AppColors.lightGrey)),
                    child: Text('${t.$2}  ${t.$1}',
                        style: TextStyle(
                            color: sel ? Colors.white : AppColors.textDark,
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList()),
            const SizedBox(height: 12),
            buildDialogField(fareCtrl, 'Base Fare (₱)',
                type: TextInputType.number),
            const SizedBox(height: 10),
            Row(children: [
              const Text('Active: ',
                  style: TextStyle(color: AppColors.textMid)),
              Switch(
                value: active,
                activeThumbColor: AppColors.blue,
                onChanged: (v) => sd(() => active = v),
              ),
            ]),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMid))),
            TextButton(
              onPressed: () async {
                final fare = double.tryParse(fareCtrl.text) ?? 0;
                await _repo.add(TransportModel(
                    name:   selectedName,
                    fare:   fare,
                    active: active,
                    emoji:  selectedEmoji));
                if (ctx.mounted) { Navigator.pop(ctx); await _load(); }
              },
              child: const Text('Add',
                  style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }

  void _showDetail(TransportModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SheetHandle(),
          Row(children: [
            Text(item.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(item.name, style: const TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 4),
              StatusBadge(active: item.active),
            ])),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.blue),
              onPressed: () { Navigator.pop(context); _showEditDialog(item); }),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.red),
              onPressed: () async {
                Navigator.pop(context);
                final ok = await showDeleteDialog(context, item.name);
                if (ok == true) { await _repo.delete(item.id!); await _load(); }
              }),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Regular Fare',
                    style: TextStyle(color: AppColors.textMid, fontSize: 14)),
                Text('₱${item.fare.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.textDark,
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Discounted Fare (20% off)',
                    style: TextStyle(color: AppColors.textMid, fontSize: 14)),
                Text('₱${item.fareFor(true).toStringAsFixed(2)}',
                    style: const TextStyle(color: Color(0xFF2E7D32),
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ]),
              const Divider(color: AppColors.divider, height: 20),
              const FareToggle(),
            ]),
          ),
          const SizedBox(height: 20),
          BlueBtn(label: 'Select This Transport', onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${item.name} selected!'),
                backgroundColor: AppColors.blue));
          }),
        ]),
      ),
    );
  }

  void _showEditDialog(TransportModel item) {
    final fareCtrl = TextEditingController(text: item.fare.toString());
    String selectedName  = _allowedTypes
        .any((t) => t.$1 == item.name)
        ? item.name
        : _allowedTypes[0].$1;
    String selectedEmoji = _allowedTypes
        .firstWhere((t) => t.$1 == selectedName,
            orElse: () => _allowedTypes[0]).$2;
    bool active = item.active;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, sd) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Transportation',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Align(alignment: Alignment.centerLeft,
                child: Text('Type', style: TextStyle(color: AppColors.textMid,
                    fontSize: 13, fontWeight: FontWeight.w600))),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8,
              children: _allowedTypes.map((t) {
                final sel = selectedName == t.$1;
                return GestureDetector(
                  onTap: () => sd(() { selectedName = t.$1; selectedEmoji = t.$2; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.blue : AppColors.offWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? AppColors.blue : AppColors.lightGrey)),
                    child: Text('${t.$2}  ${t.$1}',
                        style: TextStyle(
                            color: sel ? Colors.white : AppColors.textDark,
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList()),
            const SizedBox(height: 12),
            buildDialogField(fareCtrl, 'Base Fare (₱)',
                type: TextInputType.number),
            const SizedBox(height: 10),
            Row(children: [
              const Text('Active: ', style: TextStyle(color: AppColors.textMid)),
              Switch(
                value: active,
                activeThumbColor: AppColors.blue,
                onChanged: (v) => sd(() => active = v),
              ),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textMid))),
            TextButton(
              onPressed: () async {
                await _repo.update(item.copyWith(
                  name:   selectedName,
                  fare:   double.tryParse(fareCtrl.text) ?? item.fare,
                  active: active,
                  emoji:  selectedEmoji,
                ));
                if (ctx.mounted) { Navigator.pop(ctx); await _load(); }
              },
              child: const Text('Save',
                  style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PageHeader(
        title: 'Transportation',
        onAdd: _showAddDialog,
        onSearch: _onSearch,
      ),
      const PassengerTypeSelector(),
      Expanded(
        child: _loading
            ? const LoadingState()
            : _filtered.isEmpty
                ? const EmptyState()
                : RefreshIndicator(
                    color: AppColors.blue,
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const Divider(
                          color: AppColors.divider, height: 1,
                          indent: 76, endIndent: 16),
                      itemBuilder: (_, i) {
                        final t = _filtered[i];
                        return ListTile(
                          onTap: () => _showDetail(t),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                                color: AppColors.offWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider)),
                            child: Center(child: Text(t.emoji,
                                style: const TextStyle(fontSize: 26)))),
                          title: Column(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            StatusBadge(active: t.active),
                            const SizedBox(height: 2),
                            Text(t.name, style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w700, fontSize: 15)),
                          ]),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: FareDisplay(fare: t.fare, compact: true)),
                          trailing: const Icon(Icons.chevron_right,
                              color: AppColors.textLight),
                        );
                      },
                    ),
                  ),
      ),
    ]);
  }
}
