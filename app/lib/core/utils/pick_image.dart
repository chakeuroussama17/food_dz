import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class PickedImage {
  const PickedImage(this.bytes, this.extension);
  final Uint8List bytes;
  final String extension;
}

class ImageTooLarge implements Exception {}

/// Opens the gallery (or the camera when [camera]) and returns a resized
/// photo, or null if cancelled. In browsers the camera option opens the
/// phone camera, or a file chooser on a computer.
/// Photos are scaled down on the device before upload (faster on slow
/// connections). Throws [ImageTooLarge] above [maxBytes].
Future<PickedImage?> pickImage({
  double maxSide = 1024,
  int maxBytes = 3 * 1024 * 1024,
  bool camera = false,
}) async {
  final file = await ImagePicker().pickImage(
    source: camera ? ImageSource.camera : ImageSource.gallery,
    maxWidth: maxSide,
    maxHeight: maxSide,
    imageQuality: 80,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  if (bytes.length > maxBytes) throw ImageTooLarge();
  final name = file.name.toLowerCase();
  final ext = name.contains('.') ? name.split('.').last : 'jpg';
  return PickedImage(bytes, const {'png', 'webp'}.contains(ext) ? ext : 'jpg');
}
