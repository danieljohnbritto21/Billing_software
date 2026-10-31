import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SettingsRepository(db);
});

final settingsStreamProvider = StreamProvider<Map<String, String>>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchSettings();
});

class SettingsRepository {
  final AppDatabase _db;

  SettingsRepository(this._db);

  static const String keyBusinessName = 'business_name';
  static const String keyTagline = 'business_tagline';
  static const String keyAddress = 'business_address';
  static const String keyPhone = 'business_phone';
  static const String keyGstin = 'business_gstin';
  static const String keyInvoicePrefix = 'invoice_prefix';
  static const String keyShowNoteOnReceipt = 'show_note_on_receipt';
  static const String keyReceiptFooter = 'receipt_footer';
  static const String keyPrinterWidth = 'printer_width'; // '58mm' or '80mm'

  static const Map<String, String> defaultSettings = {
    keyBusinessName: 'FoodBill Pro Restaurant',
    keyTagline: 'Delicious Food & Great Moments',
    keyAddress: '123 Gourmet Avenue, Food Street',
    keyPhone: '+91 98765 43210',
    keyGstin: '29ABCDE1234F1Z5',
    keyInvoicePrefix: 'INV-',
    keyShowNoteOnReceipt: 'true',
    keyReceiptFooter: 'Thank you for your visit! Have a wonderful day.',
    keyPrinterWidth: '80mm',
  };

  Stream<Map<String, String>> watchSettings() {
    return _db.select(_db.appSettings).watch().map((rows) {
      final map = Map<String, String>.from(defaultSettings);
      for (final row in rows) {
        map[row.key] = row.value;
      }
      return map;
    });
  }

  Future<Map<String, String>> getAllSettings() async {
    final rows = await _db.select(_db.appSettings).get();
    final map = Map<String, String>.from(defaultSettings);
    for (final row in rows) {
      map[row.key] = row.value;
    }
    return map;
  }

  Future<String> getSetting(String key, {String? defaultValue}) async {
    final row = await (_db.select(_db.appSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value ?? defaultValue ?? defaultSettings[key] ?? '';
  }

  Future<void> setSetting(String key, String value) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: value,
          ),
        );
  }

  Future<void> saveSettings(Map<String, String> newSettings) async {
    await _db.transaction(() async {
      for (final entry in newSettings.entries) {
        await _db.into(_db.appSettings).insertOnConflictUpdate(
              AppSettingsCompanion.insert(
                key: entry.key,
                value: entry.value,
              ),
            );
      }
    });
  }
}
