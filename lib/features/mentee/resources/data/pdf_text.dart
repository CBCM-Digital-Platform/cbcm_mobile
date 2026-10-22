import 'dart:typed_data';
import 'package:pdfrx/pdfrx.dart';

/// All the readable text in a PDF. Empty for scanned documents.
Future<String> extractPdfText(Uint8List bytes) async {
  PdfDocument? doc;
  try {
    doc = await PdfDocument.openData(bytes, sourceName: 'read-aloud');
    final buffer = StringBuffer();
    for (final page in doc.pages) {
      final text = await page.loadText();
      buffer.write(text?.fullText ?? '');
      buffer.write(' ');
    }
    return buffer.toString();
  } finally {
    try {
      await doc?.dispose();
    } catch (_) {}
  }
}