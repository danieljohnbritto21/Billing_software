import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'api_client.dart';

class DeviceInfo {
  final String deviceUid;
  final String deviceName;
  final bool isAuthorized;
  final String? ipAddress;
  final DateTime? lastSeenAt;

  const DeviceInfo({
    required this.deviceUid,
    required this.deviceName,
    required this.isAuthorized,
    this.ipAddress,
    this.lastSeenAt,
  });

  /// Backward-compatible alias for ipAddress
  String? get tailscaleIp => ipAddress;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceUid: json['device_uid'] ?? json['deviceUid'] ?? '',
      deviceName: json['device_name'] ?? json['deviceName'] ?? 'Unknown Device',
      isAuthorized: json['is_authorized'] ?? json['isAuthorized'] ?? false,
      ipAddress: json['ip_address'] ?? json['ipAddress'] ?? json['tailscale_ip'] ?? json['tailscaleIp'],
      lastSeenAt: json['last_seen_at'] != null ? DateTime.tryParse(json['last_seen_at']) : null,
    );
  }
}

class DeviceService {
  final AppDatabase _db;
  final ApiClient _api;
  final _uuid = const Uuid();

  DeviceService(this._db, this._api);

  /// Retrieves or generates a persistent device UUID for this physical phone
  Future<String> getOrGenerateDeviceUid() async {
    final existing = await (_db.select(_db.appSettings)..where((s) => s.key.equals('device_uid'))).getSingleOrNull();
    if (existing != null && existing.value.isNotEmpty) {
      _api.setDeviceId(existing.value);
      return existing.value;
    }

    final newUid = _uuid.v4();
    await _db.into(_db.appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: 'device_uid', value: newUid),
    );
    _api.setDeviceId(newUid);
    return newUid;
  }

  Future<String> getDeviceName() async {
    final existing = await (_db.select(_db.appSettings)..where((s) => s.key.equals('device_name'))).getSingleOrNull();
    return existing?.value ?? 'FoodBill Terminal';
  }

  Future<void> setDeviceName(String name) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: 'device_name', value: name),
    );
  }

  /// Registers this device with the backend
  Future<DeviceInfo?> registerDevice() async {
    final uid = await getOrGenerateDeviceUid();
    final name = await getDeviceName();

    try {
      final res = await _api.post('/devices/register', body: {
        'deviceUid': uid,
        'deviceName': name,
      });
      if (res is Map<String, dynamic>) {
        return DeviceInfo.fromJson(res);
      }
    } catch (_) {
      // Offline or network error
    }
    return null;
  }

  /// Admin: list all registered devices for the business
  Future<List<Map<String, dynamic>>> listRegisteredDevices() async {
    final res = await _api.get('/devices');
    if (res is List) {
      return List<Map<String, dynamic>>.from(res);
    }
    return [];
  }

  /// Admin: authorize or revoke a device
  Future<bool> setDeviceAuthorization(String deviceId, bool isAuthorized) async {
    try {
      await _api.put('/devices/$deviceId/authorization', body: {
        'isAuthorized': isAuthorized,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
