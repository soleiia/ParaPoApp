import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:para_po/core/database/database_helper.dart';
import 'package:para_po/features/shell/main_shell.dart';
import 'package:para_po/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
  );
  await DatabaseHelper.instance.database;
  runApp(const ParaPoApp());
}

class ParaPoApp extends StatelessWidget {
  const ParaPoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Para Po',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainShell(),
    );
  }
}
