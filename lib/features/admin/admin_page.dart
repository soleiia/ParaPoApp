import 'package:flutter/material.dart';
import 'package:para_po/core/database/database_helper.dart';
import 'package:para_po/core/repositories/repositories.dart';
import 'package:para_po/core/theme/app_theme.dart';
import 'package:para_po/shared/widgets/widgets.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _authenticated = false;
  final _pinCtrl = TextEditingController();
  String _pinError = '';

  // Stats
  int _transportCount = 0, _routeCount = 0, _terminalCount = 0, _zoneCount = 0;
  bool _loadingStats = true;
  String _dbVersion = 'v2';

  @override
  void dispose() { _pinCtrl.dispose(); super.dispose(); }

  Future<void> _verifyPin() async {
    final storedPin = await DatabaseHelper.instance.getSetting('admin_pin') ?? '1234';
    if (_pinCtrl.text.trim() == storedPin) {
      setState(() { _authenticated = true; _pinError = ''; });
      _loadStats();
    } else {
      setState(() => _pinError = 'Incorrect PIN. Try again.');
      _pinCtrl.clear();
    }
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    final db = DatabaseHelper.instance;
    final results = await Future.wait([
      db.count('transportation'),
      db.count('routes'),
      db.count('terminals'),
      db.count('zones'),
    ]);
    setState(() {
      _transportCount = results[0];
      _routeCount     = results[1];
      _terminalCount  = results[2];
      _zoneCount      = results[3];
      _loadingStats   = false;
    });
  }

  Future<void> _changePin() async {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Change Admin PIN', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        buildDialogField(currentCtrl, 'Current PIN'),
        const SizedBox(height: 10),
        buildDialogField(newCtrl, 'New PIN (min 4 digits)'),
        const SizedBox(height: 10),
        buildDialogField(confirmCtrl, 'Confirm New PIN'),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMid))),
        TextButton(onPressed: () async {
          final stored = await DatabaseHelper.instance.getSetting('admin_pin') ?? '1234';
          if (currentCtrl.text != stored) {
            if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Current PIN is incorrect'), backgroundColor: AppColors.red));
            return;
          }
          if (newCtrl.text.length < 4) {
            if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('PIN must be at least 4 digits'), backgroundColor: AppColors.red));
            return;
          }
          if (newCtrl.text != confirmCtrl.text) {
            if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('PINs do not match'), backgroundColor: AppColors.red));
            return;
          }
          await DatabaseHelper.instance.setSetting('admin_pin', newCtrl.text);
          if (ctx.mounted) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN changed successfully!'), backgroundColor: AppColors.green));
          }
        }, child: const Text('Change', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700))),
      ],
    ));
  }

  Future<void> _resetDatabase() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Reset Database', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.red)),
      content: const Text('This will DELETE ALL DATA and reload the default Cabuyao data. This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('RESET', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w800))),
      ],
    ));
    if (confirm != true) return;

    // Delete all rows then re-seed
    final db = await DatabaseHelper.instance.database;
    for (final table in ['transportation', 'routes', 'terminals', 'zones']) {
      await db.delete(table);
    }
    // Re-seed by reopening (hack: close and delete file so onCreate runs again)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database reset. Please restart the app to reload seed data.'),
            backgroundColor: AppColors.blue));
    }
  }

  Future<void> _showTableData(String table) async {
    final rows = await DatabaseHelper.instance.queryAll(table);
    if (!mounted) return;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('$table (${rows.length} rows)', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      content: SizedBox(width: 400, height: 400,
        child: rows.isEmpty ? const Center(child: Text('No data'))
            : SingleChildScrollView(scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(child: DataTable(
                  columns: rows.first.keys.map((k) => DataColumn(
                    label: Text(k, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)))).toList(),
                  rows: rows.map((row) => DataRow(
                    cells: row.values.map((v) => DataCell(
                      Text(v?.toString() ?? 'null',
                          style: const TextStyle(fontSize: 11)))).toList())).toList(),
                )))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.blue))),
      ],
    ));
  }

  // ── PIN Screen ─────────────────────────────────────────────────────────────
  Widget _buildPinScreen() {
    return Container(
      color: AppColors.offWhite,
      child: Center(child: Container(
        width: 320,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20)]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 64, height: 64,
            decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.admin_panel_settings, color: AppColors.blue, size: 36)),
          const SizedBox(height: 20),
          const Text('Admin Access', style: TextStyle(color: AppColors.textDark, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Enter your PIN to continue', style: TextStyle(color: AppColors.textMid, fontSize: 14)),
          const SizedBox(height: 24),
          TextField(
            controller: _pinCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 8,
            decoration: InputDecoration(
              hintText: '••••',
              hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 24, letterSpacing: 8),
              filled: true, fillColor: AppColors.offWhite,
              counterText: '',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.blue, width: 2)),
              errorText: _pinError.isNotEmpty ? _pinError : null,
            ),
            style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w800),
            onSubmitted: (_) => _verifyPin(),
          ),
          const SizedBox(height: 20),
          BlueBtn(label: 'Enter', onTap: _verifyPin),
          const SizedBox(height: 12),
          Text('Default PIN: 1234', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
        ]),
      )),
    );
  }

  // ── Admin Dashboard ────────────────────────────────────────────────────────
  Widget _buildDashboard() {
    return Column(children: [
      // Header
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1A237E), AppColors.blueDark],
              begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SafeArea(bottom: false, child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 18),
          child: Row(children: [
            const Icon(Icons.admin_panel_settings, color: Colors.white, size: 26),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              Text('Para Po Developer Tools', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ])),
            GestureDetector(
              onTap: () => setState(() => _authenticated = false),
              child: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.logout, color: Colors.white, size: 18)),
            ),
          ]),
        )),
      ),

      Expanded(child: _loadingStats ? const LoadingState()
        : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Database stats ────────────────────────────────────────────
          const Text('Database Overview', style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.8,
            children: [
              _StatCard(label: 'Transport Options', count: _transportCount, icon: Icons.directions_bus, color: AppColors.blue,
                  onTap: () => _showTableData('transportation')),
              _StatCard(label: 'Routes', count: _routeCount, icon: Icons.route, color: AppColors.green,
                  onTap: () => _showTableData('routes')),
              _StatCard(label: 'Terminals', count: _terminalCount, icon: Icons.place, color: const Color(0xFFEF6C00),
                  onTap: () => _showTableData('terminals')),
              _StatCard(label: 'Zones', count: _zoneCount, icon: Icons.grid_view, color: const Color(0xFF8E24AA),
                  onTap: () => _showTableData('zones')),
            ]),
          const SizedBox(height: 8),
          Text('Tap any card to view raw table data', style: TextStyle(color: AppColors.textLight, fontSize: 11)),

          const SizedBox(height: 24),
          // ── Actions ────────────────────────────────────────────────────
          const Text('Admin Actions', style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),

          _ActionTile(icon: Icons.lock_reset, color: AppColors.blue, label: 'Change Admin PIN',
              subtitle: 'Update the 4–8 digit PIN for admin access', onTap: _changePin),
          _ActionTile(icon: Icons.refresh, color: const Color(0xFFEF6C00), label: 'Reload Stats',
              subtitle: 'Refresh database record counts', onTap: () async { await _loadStats(); }),
          _ActionTile(icon: Icons.storage, color: AppColors.green, label: 'View Settings Table',
              subtitle: 'See all stored app settings', onTap: () => _showTableData('settings')),
          _ActionTile(icon: Icons.delete_forever, color: AppColors.red, label: 'Reset Database',
              subtitle: 'Delete all data and reload Cabuyao seed data', onTap: _resetDatabase),

          const SizedBox(height: 24),
          // ── App info ──────────────────────────────────────────────────
          const Text('App Information', style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider)),
            child: Column(children: const [
              DetailRow('App Name', 'Para Po'),
              Divider(color: AppColors.divider),
              DetailRow('Version', '1.0.0+2'),
              Divider(color: AppColors.divider),
              DetailRow('Database Version', 'v2'),
              Divider(color: AppColors.divider),
              DetailRow('Coverage Area', 'Cabuyao, Laguna PH'),
              Divider(color: AppColors.divider),
              DetailRow('Map (Mobile)', 'Google Maps API'),
              Divider(color: AppColors.divider),
              DetailRow('Map (Desktop)', 'OSRM + OpenStreetMap'),
            ])),
        ]))),
    ]);
  }

  @override
  Widget build(BuildContext context) =>
      _authenticated ? _buildDashboard() : _buildPinScreen();
}

class _StatCard extends StatelessWidget {
  final String label; final int count; final IconData icon; final Color color; final VoidCallback onTap;
  const _StatCard({required this.label, required this.count, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: color, size: 22),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: const Text('VIEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textMid))),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMid, fontWeight: FontWeight.w500)),
        ]),
      ]),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon; final Color color; final String label, subtitle; final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.color, required this.label, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider)),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 14)),
          Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
        ])),
        const Icon(Icons.chevron_right, color: AppColors.textLight),
      ]),
    ),
  );
}
