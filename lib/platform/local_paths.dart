import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalPaths {
  const LocalPaths();

  Future<Directory> documents() => getApplicationDocumentsDirectory();

  Future<Directory> attachments() async {
    final root = await documents();
    final dir = Directory(p.join(root.path, 'attachments'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> tempExports() async {
    final root = await getTemporaryDirectory();
    final dir = Directory(p.join(root.path, 'tripbanban_exports'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<File> resolveRelative(String relativePath) async {
    final root = await documents();
    return File(p.join(root.path, relativePath));
  }
}
