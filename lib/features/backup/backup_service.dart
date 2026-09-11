import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../../data/local/app_database.dart';
import '../../platform/local_paths.dart';
import 'snapshot_service.dart';

class BackupInfo {
  const BackupInfo({
    required this.createdAt,
    required this.schemaVersion,
    required this.appVersion,
    required this.tripCount,
    required this.expenseCount,
    required this.attachmentCount,
  });

  final DateTime createdAt;
  final int schemaVersion;
  final String appVersion;
  final int tripCount;
  final int expenseCount;
  final int attachmentCount;
}

class LocalBackupService {
  LocalBackupService(this.db, {LocalPaths? paths})
      : _paths = paths ?? const LocalPaths(),
        _snapshot = SnapshotService(db);

  static const appVersion = '0.8.1';
  static const backupFormatVersion = 1;

  final AppDatabase db;
  final LocalPaths _paths;
  final SnapshotService _snapshot;

  Future<File> createAccountBackup({String? outputPath}) async {
    final snapshot = await _snapshot.exportJson();
    final attachments = await db.select(db.attachments).get();
    final manifest = <String, dynamic>{
      'format': 'TripBanBan',
      'backupFormatVersion': backupFormatVersion,
      'schemaVersion': db.schemaVersion,
      'appVersion': appVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'tripCount': (snapshot['trips'] as List).length,
      'expenseCount': (snapshot['expenses'] as List).length,
      'attachmentCount': attachments.length,
    };

    final archive = Archive()
      ..addFile(_jsonFile('manifest.json', manifest))
      ..addFile(_jsonFile('snapshot.json', snapshot));

    for (final attachment in attachments) {
      final file = await _paths.resolveRelative(attachment.relativePath);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      final safeName = _safeArchivePath('files/${attachment.relativePath}');
      archive.addFile(ArchiveFile(safeName, bytes.length, bytes));
    }

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) throw StateError('Failed to create TripBanBan backup.');
    final target = outputPath == null
        ? File(p.join((await _paths.tempExports()).path, 'TripBanBan_${_stamp()}.tripbanban'))
        : File(outputPath);
    await target.parent.create(recursive: true);
    await target.writeAsBytes(encoded, flush: true);
    return target;
  }

  Future<BackupInfo> inspectBackup(File file) async {
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes(), verify: true);
    final manifest = _jsonFromArchive(archive, 'manifest.json');
    _validateManifest(manifest);
    return BackupInfo(
      createdAt: DateTime.parse(manifest['createdAt'] as String),
      schemaVersion: manifest['schemaVersion'] as int,
      appVersion: manifest['appVersion'] as String,
      tripCount: manifest['tripCount'] as int? ?? 0,
      expenseCount: manifest['expenseCount'] as int? ?? 0,
      attachmentCount: manifest['attachmentCount'] as int? ?? 0,
    );
  }

  /// Destructive account restore. UI must show preview + explicit confirmation first.
  Future<void> restoreAccountBackup(File file) async {
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes(), verify: true);
    final manifest = _jsonFromArchive(archive, 'manifest.json');
    _validateManifest(manifest);
    final snapshot = _jsonFromArchive(archive, 'snapshot.json');

    final documents = await _paths.documents();
    final attachmentRoot = Directory(p.join(documents.path, 'attachments'));
    final stagedRoot = Directory(p.join((await _paths.tempExports()).path, 'restore_${DateTime.now().microsecondsSinceEpoch}'));
    await stagedRoot.create(recursive: true);

    for (final entry in archive.files) {
      if (!entry.isFile || !entry.name.startsWith('files/')) continue;
      final relative = _safeArchivePath(entry.name.substring('files/'.length));
      final target = File(p.join(stagedRoot.path, relative));
      await target.parent.create(recursive: true);
      final content = entry.content;
      if (content is! List<int>) throw const FormatException('Invalid backup file content.');
      await target.writeAsBytes(content, flush: true);
    }

    await _snapshot.restoreJson(snapshot);

    if (await attachmentRoot.exists()) {
      await attachmentRoot.delete(recursive: true);
    }
    final stagedAttachments = Directory(p.join(stagedRoot.path, 'attachments'));
    if (await stagedAttachments.exists()) {
      await _copyDirectory(stagedAttachments, attachmentRoot);
    } else {
      await attachmentRoot.create(recursive: true);
    }
    await stagedRoot.delete(recursive: true);
  }

  ArchiveFile _jsonFile(String name, Object value) {
    final bytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(value));
    return ArchiveFile(name, bytes.length, bytes);
  }

  Map<String, dynamic> _jsonFromArchive(Archive archive, String name) {
    final file = archive.files.where((e) => e.name == name).firstOrNull;
    if (file == null || !file.isFile || file.content is! List<int>) {
      throw FormatException('Missing or invalid $name.');
    }
    final decoded = jsonDecode(utf8.decode((file.content as List<int>)));
    if (decoded is! Map<String, dynamic>) throw FormatException('$name must be a JSON object.');
    return decoded;
  }

  void _validateManifest(Map<String, dynamic> manifest) {
    if (manifest['format'] != 'TripBanBan') throw const FormatException('Not a TripBanBan backup.');
    final backupVersion = manifest['backupFormatVersion'];
    if (backupVersion != backupFormatVersion) {
      throw FormatException('Unsupported backup format version: $backupVersion');
    }
    final schemaVersion = manifest['schemaVersion'];
    if (schemaVersion is! int || schemaVersion > db.schemaVersion) {
      throw FormatException('Backup uses a newer database schema: $schemaVersion');
    }
  }

  static String _safeArchivePath(String value) {
    final normalized = p.posix.normalize(value.replaceAll('\\', '/'));
    if (normalized.startsWith('/') || normalized.startsWith('../') || normalized.contains('/../')) {
      throw const FormatException('Unsafe path in backup.');
    }
    return normalized;
  }

  static String _stamp() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
  }

  static Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      final name = p.basename(entity.path);
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(p.join(target.path, name)));
      } else if (entity is File) {
        await entity.copy(p.join(target.path, name));
      }
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
