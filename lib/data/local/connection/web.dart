import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

DatabaseConnection openConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final WasmDatabaseResult result = await WasmDatabase.open(
      databaseName: 'brolly',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return DatabaseConnection(result.resolvedExecutor);
  }));
}
