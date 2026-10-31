import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

QueryExecutor openConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));

    // Open IndexedDB VFS and register as default to prevent "no such vfs" error
    final fs = await IndexedDbFileSystem.open(dbName: 'foodbillpro_fs');
    sqlite3.registerVirtualFileSystem(fs, makeDefault: true);

    return DatabaseConnection(WasmDatabase(
      sqlite3: sqlite3,
      path: 'foodbillpro.sqlite',
    ));
  }));
}
