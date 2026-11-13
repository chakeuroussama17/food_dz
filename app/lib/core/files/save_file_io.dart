import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> saveFile(Uint8List bytes, String filename, String mimeType) =>
    SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: mimeType, name: filename)],
        fileNameOverrides: [filename],
        subject: filename,
      ),
    );
