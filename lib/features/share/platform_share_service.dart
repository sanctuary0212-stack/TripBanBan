import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:share_plus/share_plus.dart';

class PlatformShareService {
  const PlatformShareService();

  Future<ShareResult> shareFiles(
    List<File> files, {
    String? text,
    String? title,
  }) {
    return SharePlus.instance.share(
      ShareParams(
        files: files.map((file) => XFile(file.path)).toList(growable: false),
        text: text,
        title: title,
      ),
    );
  }

  Future<ShareResult> shareText(String text, {String? title}) {
    return SharePlus.instance.share(ShareParams(text: text, title: title));
  }
}
