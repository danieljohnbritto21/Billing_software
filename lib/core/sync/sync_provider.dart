import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/device_service.dart';
import '../database/database_provider.dart';
import 'sync_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final db = ref.watch(databaseProvider);
  return ApiClient(db);
});

final deviceServiceProvider = Provider<DeviceService>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(apiClientProvider);
  return DeviceService(db, api);
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(apiClientProvider);
  final deviceService = ref.watch(deviceServiceProvider);
  return SyncService(db, api, deviceService);
});

final syncStateProvider = StreamProvider<SyncState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final controller = StreamController<SyncState>();
  controller.add(syncService.state);

  void listener() {
    if (!controller.isClosed) {
      controller.add(syncService.state);
    }
  }

  syncService.addListener(listener);
  ref.onDispose(() {
    syncService.removeListener(listener);
    controller.close();
  });

  return controller.stream;
});
