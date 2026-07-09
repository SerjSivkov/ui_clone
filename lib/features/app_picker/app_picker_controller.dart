import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/installed_app.dart';
import '../capture/capture_controller.dart';

final installedAppsProvider =
    FutureProvider.autoDispose<List<InstalledApp>>((ref) async {
  final repo = ref.watch(captureRepositoryProvider);
  final apps = await repo.listInstalledApps();
  apps.sort(
    (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
  );
  return apps;
});

final appSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final filteredAppsProvider =
    Provider.autoDispose<AsyncValue<List<InstalledApp>>>((ref) {
  final query = ref.watch(appSearchQueryProvider).trim().toLowerCase();
  final apps = ref.watch(installedAppsProvider);
  return apps.whenData((list) {
    if (query.isEmpty) return list;
    return list
        .where(
          (app) =>
              app.label.toLowerCase().contains(query) ||
              app.packageName.toLowerCase().contains(query),
        )
        .toList(growable: false);
  });
});
