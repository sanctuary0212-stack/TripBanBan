import 'dart:io';

import 'package:file_selector/file_selector.dart';

import '../share/platform_share_service.dart';
import 'backup_service.dart';

class LocalBackupFacade {
  const LocalBackupFacade({required this.backups, required this.share});

  final LocalBackupService backups;
  final PlatformShareService share;

  Future<File> createAndShareBackup() async {
    final file = await backups.createAccountBackup();
    await share.shareFiles(
      [file],
      title: 'TripBanBan 備份',
      text: '旅行伴伴 TripBanBan 本機備份',
    );
    return file;
  }

  Future<File?> pickBackupFile() async {
    const type = XTypeGroup(
      label: 'TripBanBan backup',
      extensions: ['tripbanban'],
      mimeTypes: ['application/octet-stream', 'application/zip'],
      uniformTypeIdentifiers: ['public.data'],
    );
    final selected = await openFile(acceptedTypeGroups: const [type]);
    if (selected == null) return null;
    return File(selected.path);
  }
}
