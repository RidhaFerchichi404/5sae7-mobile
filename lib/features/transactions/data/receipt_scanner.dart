import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/receipt_parser.dart';

/// Takes or picks a receipt photo and reads its text with ML Kit. Runs on
/// the device: free, works offline, and the photo is never uploaded.
class ReceiptScanner {
  /// The receipt's text, or null when the user cancels.
  Future<String?> read(ImageSource source) async {
    final photo = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2000, // Enough for small print, quick to recognise.
      imageQuality: 90,
    );
    if (photo == null) {
      return null;
    }
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(photo.path),
      );
      return joinRows([
        for (final block in result.blocks)
          for (final line in block.lines)
            (
              text: line.text,
              left: line.boundingBox.left,
              top: line.boundingBox.top,
              height: line.boundingBox.height,
            ),
      ]);
    } finally {
      await recognizer.close();
    }
  }
}
