import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Lokale Ablage von Auftragsdateien unter Application Support — ein Ordner pro Auftrag.
/// Dateien werden wie im Windows-Explorer verwaltet (Kopieren, Umbenennen, alle Typen).
abstract final class OrderAttachmentService {
  /// Stellt den Auftragsordner bereit (`…/order_attachments/<Erstellzeitpunkt>/`).
  static Future<Directory> orderDirectory(DateTime orderCreatedAt) async {
    final root = await getApplicationSupportDirectory();
    final id = orderCreatedAt.millisecondsSinceEpoch.toString();
    final dir = Directory(p.join(root.path, 'order_attachments', id));
    await dir.create(recursive: true);
    return dir;
  }

  /// Öffnet den Auftragsordner im System-Dateimanager (Explorer / Finder / …).
  static Future<bool> openOrderFolder(DateTime orderCreatedAt) async {
    final dir = await orderDirectory(orderCreatedAt);
    final path = dir.path;
    try {
      if (Platform.isWindows) {
        await Process.run('explorer', [path]);
        return true;
      }
      if (Platform.isMacOS) {
        await Process.run('open', [path]);
        return true;
      }
      if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Entfernt die Datei von der Platte, falls sie unter unserem Ablageordner liegt.
  static Future<void> deleteIfManaged(String filePath) async {
    try {
      final root = await getApplicationSupportDirectory();
      final base = p.normalize(p.join(root.path, 'order_attachments'));
      final normalized = p.normalize(filePath);
      if (!normalized.toLowerCase().startsWith(base.toLowerCase())) {
        return;
      }
      final f = File(filePath);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Ignorieren
    }
  }
}
