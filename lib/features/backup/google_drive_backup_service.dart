import 'dart:async';
import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:path_provider/path_provider.dart';

import '../../data/repositories/ledger_repository.dart';
import 'backup_service.dart';

class GoogleDriveBackupState {
  const GoogleDriveBackupState({
    required this.email,
    required this.displayName,
    required this.lastBackupAt,
  });

  final String email;
  final String? displayName;
  final DateTime? lastBackupAt;
}

/// Backs up TripBanBan data into the signed-in user's Google Drive AppData space.
///
/// There is no TripBanBan server in this flow. OAuth and file transfer are
/// directly between the app and Google Drive.
class GoogleDriveBackupService {
  GoogleDriveBackupService({
    required this.localBackup,
    required this.repository,
  });

  static const _backupFileName = 'tripbanban_account_v1.tripbanban';
  static const _lastBackupSettingKey = 'googleDrive.lastBackupAt';
  static const _scopes = <String>[drive.DriveApi.driveAppdataScope];

  final LocalBackupService localBackup;
  final LedgerRepository repository;

  final GoogleSignIn _signIn = GoogleSignIn.instance;
  bool _initialized = false;
  GoogleSignInAccount? _account;

  Future<void> initialize() async {
    if (_initialized) return;
    await _signIn.initialize();
    _signIn.authenticationEvents.listen((event) {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn():
          _account = event.user;
          break;
        case GoogleSignInAuthenticationEventSignOut():
          _account = null;
          break;
      }
    });
    final lightweight = _signIn.attemptLightweightAuthentication();
    if (lightweight != null) {
      try {
        _account = await lightweight;
      } catch (_) {
        // Silent auth failure is normal when the user has never connected Drive.
      }
    }
    _initialized = true;
  }

  /// Must be called from an explicit user action because authorization can show UI.
  Future<GoogleDriveBackupState> connectInteractive() async {
    await initialize();
    final account = _account ?? await _signIn.authenticate(scopeHint: _scopes);
    _account = account;
    await _authorizationFor(account, interactive: true);
    return state();
  }

  Future<void> disconnect() async {
    await initialize();
    await _signIn.signOut();
    _account = null;
  }

  Future<GoogleDriveBackupState> state() async {
    await initialize();
    final account = _account;
    final raw = await repository.getSetting(_lastBackupSettingKey);
    return GoogleDriveBackupState(
      email: account?.email ?? '',
      displayName: account?.displayName,
      lastBackupAt: raw == null ? null : DateTime.tryParse(raw),
    );
  }

  /// Creates a fresh local snapshot and uploads/replaces the single AppData backup.
  /// Returns false when Drive isn't connected or silent authorization isn't available.
  Future<bool> backupNow({bool allowInteractiveAuthorization = false}) async {
    await initialize();
    final account = _account;
    if (account == null) return false;
    final authorization = await _authorizationFor(
      account,
      interactive: allowInteractiveAuthorization,
    );
    if (authorization == null) return false;

    final auth.AuthClient client = authorization.authClient(scopes: _scopes);
    try {
      final api = drive.DriveApi(client);
      final backup = await localBackup.createAccountBackup();
      final existing = await _findBackup(api);
      final media = drive.Media(backup.openRead(), await backup.length());
      final metadata = drive.File(
        name: _backupFileName,
        mimeType: 'application/octet-stream',
        appProperties: {
          'format': 'TripBanBan',
          'backupVersion': '1',
        },
      );
      if (existing?.id == null) {
        metadata.parents = const ['appDataFolder'];
        await api.files.create(metadata, uploadMedia: media, $fields: 'id,modifiedTime,size');
      } else {
        await api.files.update(
          metadata,
          existing!.id!,
          uploadMedia: media,
          $fields: 'id,modifiedTime,size',
        );
      }
      final now = DateTime.now().toUtc();
      await repository.setSetting(_lastBackupSettingKey, now.toIso8601String());
      return true;
    } finally {
      client.close();
    }
  }

  Future<BackupInfo?> inspectRemoteBackup({bool allowInteractiveAuthorization = false}) async {
    final file = await _downloadRemoteBackup(allowInteractiveAuthorization: allowInteractiveAuthorization);
    if (file == null) return null;
    return localBackup.inspectBackup(file);
  }

  /// Downloads the AppData backup. The caller should show [BackupInfo] and ask
  /// for destructive restore confirmation before calling this method.
  Future<bool> restoreRemoteBackup({bool allowInteractiveAuthorization = true}) async {
    final file = await _downloadRemoteBackup(allowInteractiveAuthorization: allowInteractiveAuthorization);
    if (file == null) return false;
    await localBackup.restoreAccountBackup(file);
    return true;
  }

  Future<File?> _downloadRemoteBackup({required bool allowInteractiveAuthorization}) async {
    await initialize();
    final account = _account;
    if (account == null) return null;
    final authorization = await _authorizationFor(
      account,
      interactive: allowInteractiveAuthorization,
    );
    if (authorization == null) return null;

    final auth.AuthClient client = authorization.authClient(scopes: _scopes);
    try {
      final api = drive.DriveApi(client);
      final remote = await _findBackup(api);
      if (remote?.id == null) return null;
      final object = await api.files.get(
        remote!.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      if (object is! drive.Media) return null;
      final tempDir = await getTemporaryDirectory();
      final download = File('${tempDir.path}/TripBanBan_drive_${DateTime.now().microsecondsSinceEpoch}.tripbanban');
      final sink = download.openWrite();
      await object.stream.pipe(sink);
      return download;
    } finally {
      client.close();
    }
  }

  Future<drive.File?> _findBackup(drive.DriveApi api) async {
    final result = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupFileName' and trashed = false",
      pageSize: 10,
      $fields: 'files(id,name,modifiedTime,size,appProperties)',
    );
    final files = result.files ?? const <drive.File>[];
    if (files.isEmpty) return null;
    files.sort((a, b) {
      final aa = a.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bb = b.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bb.compareTo(aa);
    });
    return files.first;
  }

  Future<GoogleSignInClientAuthorization?> _authorizationFor(
    GoogleSignInAccount account, {
    required bool interactive,
  }) async {
    final existing = await account.authorizationClient.authorizationForScopes(_scopes);
    if (existing != null) return existing;
    if (!interactive) return null;
    return account.authorizationClient.authorizeScopes(_scopes);
  }
}
