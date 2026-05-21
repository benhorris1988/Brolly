import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

DatabaseConnection openConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, 'brolly.sqlite'));
    return DatabaseConnection(NativeDatabase.createInBackground(file));
  }));
}
