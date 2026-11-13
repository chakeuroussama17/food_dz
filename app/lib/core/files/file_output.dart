import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'save_file_io.dart'
    if (dart.library.js_interop) 'save_file_web.dart'
    as impl;

/// Saves a generated file (CSV export): a download in the browser, the share
/// sheet on phones (save to Files / Drive, send by WhatsApp...).
/// Overridden in tests.
abstract interface class FileOutput {
  Future<void> save(Uint8List bytes, String filename, String mimeType);
}

class PlatformFileOutput implements FileOutput {
  @override
  Future<void> save(Uint8List bytes, String filename, String mimeType) =>
      impl.saveFile(bytes, filename, mimeType);
}

final fileOutputProvider = Provider<FileOutput>((ref) => PlatformFileOutput());
