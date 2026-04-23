import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Kompakte Info über eine im Auftragsordner abgelegte Datei.
class OrderAttachment {
  const OrderAttachment({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final DateTime modifiedAt;
}

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

  /// Listet alle Dateien im Auftragsordner (nicht rekursiv), neueste zuerst.
  static Future<List<OrderAttachment>> listAttachments(
    DateTime orderCreatedAt,
  ) async {
    final dir = await orderDirectory(orderCreatedAt);
    final result = <OrderAttachment>[];
    await for (final e in dir.list(followLinks: false)) {
      if (e is File) {
        final stat = await e.stat();
        result.add(
          OrderAttachment(
            path: e.path,
            name: p.basename(e.path),
            sizeBytes: stat.size,
            modifiedAt: stat.modified,
          ),
        );
      }
    }
    result.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return result;
  }

  /// Kopiert [sourcePaths] in den Auftragsordner und vergibt bei Namenskonflikten
  /// eine eindeutige Kopie-Variante (`name (2).pdf`). Gibt die neuen Pfade zurück.
  static Future<List<String>> addAttachments(
    DateTime orderCreatedAt,
    Iterable<String> sourcePaths,
  ) async {
    final dir = await orderDirectory(orderCreatedAt);
    final added = <String>[];
    for (final src in sourcePaths) {
      final srcFile = File(src);
      if (!await srcFile.exists()) continue;
      final baseName = p.basename(src);
      final target = await _uniqueTargetPath(dir, baseName);
      await srcFile.copy(target);
      added.add(target);
    }
    return added;
  }

  static Future<String> _uniqueTargetPath(
    Directory dir,
    String fileName,
  ) async {
    final ext = p.extension(fileName);
    final stem = p.basenameWithoutExtension(fileName);
    var candidate = p.join(dir.path, fileName);
    var counter = 2;
    while (await File(candidate).exists()) {
      candidate = p.join(dir.path, '$stem ($counter)$ext');
      counter += 1;
    }
    return candidate;
  }

  /// Öffnet eine einzelne Datei mit der zugehörigen System-App (Doppelklick-Verhalten).
  static Future<bool> openFile(String filePath) async {
    try {
      if (Platform.isWindows) {
        // `start` ist ein Builtin der Shell, deshalb mit cmd /c aufrufen.
        await Process.run('cmd', ['/c', 'start', '', filePath]);
        return true;
      }
      if (Platform.isMacOS) {
        await Process.run('open', [filePath]);
        return true;
      }
      if (Platform.isLinux) {
        await Process.run('xdg-open', [filePath]);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
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

  /// Löscht die Datei im Auftragsordner. Gibt `true` zurück, wenn sie entfernt wurde.
  static Future<bool> deleteAttachment(String filePath) async {
    try {
      final f = File(filePath);
      if (!await f.exists()) return false;
      await f.delete();
      return true;
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
