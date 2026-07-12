import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'utils/update_checker.dart';
import 'widgets/update_dialog.dart';

class UiCloneApp extends ConsumerStatefulWidget {
  const UiCloneApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  ConsumerState<UiCloneApp> createState() => _UiCloneAppState();
}

class _UiCloneAppState extends ConsumerState<UiCloneApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final result = await checkForUpdateWithCache(widget.prefs);
    if (!mounted) return;
    if (result.info != null) {
      showDialog(
        context: context,
        builder: (_) => UpdateDialog(update: result.info!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UI Clone',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
