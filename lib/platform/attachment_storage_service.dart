import 'dart:io';

import 'package:drift/drift.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../data/local/app_database.dart';
import 'local_paths.dart';

class StagedAttachment {
  const StagedAttachment({required this.file, required this.type});
  final XFile file;
  final String type; // RECEIPT / PHOTO
}

class AttachmentStorageService {
  AttachmentStorageService(this.db, {LocalPaths? paths, ImagePicker? picker, Uuid? uuid})
      : _paths = paths ?? const LocalPaths(),
        _picker = picker ?? ImagePicker(),
        _uuid = uuid ?? const Uuid();

  final AppDatabase db;
  final LocalPaths _paths;
  final ImagePicker _picker;
  final Uuid _uuid;

  Future<StagedAttachment?> stageReceipt() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      maxWidth: 2200,
    );
    return picked == null ? null : StagedAttachment(file: picked, type: 'RECEIPT');
  }

  Future<List<StagedAttachment>> stagePhotos({int limit = 5}) async {
    if (limit <= 0) return const [];
    final files = limit == 1
        ? <XFile>[
            if (await _picker.pickImage(source: ImageSource.gallery, imageQuality: 88, maxWidth: 2200)
                case final XFile file?)
              file,
          ]
        : await _picker.pickMultiImage(imageQuality: 88, maxWidth: 2200, limit: limit);
    return [for (final file in files) StagedAttachment(file: file, type: 'PHOTO')];
  }

  Future<List<AttachmentRow>> persistStaged(String expenseId, Iterable<StagedAttachment> staged) async {
    final result = <AttachmentRow>[];
    for (final item in staged) {
      result.add(await _persistPicked(expenseId, item.file, type: item.type));
    }
    return result;
  }

  Future<AttachmentRow?> captureReceipt(String expenseId) async {
    final staged = await stageReceipt();
    return staged == null ? null : _persistPicked(expenseId, staged.file, type: staged.type);
  }

  Future<List<AttachmentRow>> pickPhotos(String expenseId, {int limit = 5}) async {
    final staged = await stagePhotos(limit: limit);
    return persistStaged(expenseId, staged);
  }

  Future<AttachmentRow> _persistPicked(String expenseId, XFile picked, {required String type}) async {
    final root = await _paths.documents();
    final extension = p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path).toLowerCase();
    final id = _uuid.v7();
    final relativePath = p.join('attachments', expenseId, '$id$extension');
    final target = File(p.join(root.path, relativePath));
    await target.parent.create(recursive: true);
    await File(picked.path).copy(target.path);
    final size = await target.length();
    final now = DateTime.now();
    await db.into(db.attachments).insert(
          AttachmentsCompanion.insert(
            id: id,
            expenseId: expenseId,
            type: type,
            relativePath: relativePath,
            mimeType: Value(_mimeFromExtension(extension)),
            byteLength: Value(size),
            createdAt: now,
          ),
        );
    return (db.select(db.attachments)..where((a) => a.id.equals(id))).getSingle();
  }

  Future<List<AttachmentRow>> attachmentsForExpense(String expenseId) =>
      (db.select(db.attachments)
            ..where((a) => a.expenseId.equals(expenseId))
            ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
          .get();

  Future<File> fileFor(AttachmentRow row) => _paths.resolveRelative(row.relativePath);

  Future<void> deleteAttachmentsForExpense(String expenseId) async {
    final rows = await attachmentsForExpense(expenseId);
    for (final row in rows) {
      final file = await _paths.resolveRelative(row.relativePath);
      if (await file.exists()) await file.delete();
    }
    await (db.delete(db.attachments)..where((a) => a.expenseId.equals(expenseId))).go();
  }

  Future<void> deleteAttachment(String id) async {
    final row = await (db.select(db.attachments)..where((a) => a.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    final file = await _paths.resolveRelative(row.relativePath);
    if (await file.exists()) await file.delete();
    await (db.delete(db.attachments)..where((a) => a.id.equals(id))).go();
  }

  static String? _mimeFromExtension(String extension) => switch (extension.toLowerCase()) {
        '.jpg' || '.jpeg' => 'image/jpeg',
        '.png' => 'image/png',
        '.heic' => 'image/heic',
        '.webp' => 'image/webp',
        _ => null,
      };
}
