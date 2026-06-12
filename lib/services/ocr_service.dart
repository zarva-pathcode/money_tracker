import 'dart:io';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class OcrService {
  static final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  static const _maxRetries = 2;

  /// Membuka kamera (mode filter untuk teks lebih jelas)
  static Future<String?> scanDocument() async {
    try {
      final scanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormats: {DocumentFormat.jpeg},
          mode: ScannerMode.filter,
          pageLimit: 1,
          isGalleryImport: true,
        ),
      );

      final result = await scanner.scanDocument();
      scanner.close();

      if (result.images != null && result.images!.isNotEmpty) {
        return result.images!.first;
      }
    } catch (e) {
      print("OcrService.scanDocument error: $e");
    }
    return null;
  }

  /// Ekstrak teks dengan 3 pass: original → contrast → binarization
  static Future<String> extractText(String imagePath) async {
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      String path = imagePath;

      if (attempt == 1) {
        final p = await _preprocessContrast(imagePath);
        if (p != null) path = p;
      } else if (attempt == 2) {
        final p = await _preprocessBinarize(imagePath);
        if (p != null) path = p;
      }

      try {
        final inputImage = InputImage.fromFilePath(path);
        final recognizedText = await _textRecognizer.processImage(inputImage);
        final text = recognizedText.text.trim();

        if (text.isNotEmpty && text.length > 10) {
          return text;
        }
      } catch (e) {
        print("OcrService.extractText attempt $attempt error: $e");
      }
    }

    return "";
  }

  /// Pass 1: grayscale + kontras + sharpen
  static Future<String?> _preprocessContrast(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) return null;

      final gray = img.grayscale(original);
      final enhanced = img.adjustColor(gray, contrast: 1.8, brightness: 0.05);
      final sharp = img.convolution(enhanced, filter: [
        -1, -1, -1,
        -1,  9, -1,
        -1, -1, -1,
      ], div: 1, offset: 0);

      return await _saveTemp(sharp, 'contrast_');
    } catch (e) {
      print("OcrService._preprocessContrast error: $e");
      return null;
    }
  }

  /// Pass 2: binarization (hitam-putih tegas) untuk thermal paper
  static Future<String?> _preprocessBinarize(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) return null;

      final gray = img.grayscale(original);
      final bw = _adaptiveThreshold(gray);
      final sharp = img.convolution(bw, filter: [
        -1, -1, -1,
        -1,  9, -1,
        -1, -1, -1,
      ], div: 1, offset: 0);

      return await _saveTemp(sharp, 'bw_');
    } catch (e) {
      print("OcrService._preprocessBinarize error: $e");
      return null;
    }
  }

  /// Thresholding adaptif: pixel > mean*1.15 → putih, sisanya hitam
  static img.Image _adaptiveThreshold(img.Image src) {
    int total = 0;
    final count = src.width * src.height;
    for (final p in src) {
      total += p.r.toInt();
    }
    final mean = total ~/ count;
    final threshold = (mean * 1.15).clamp(90, 200).toInt();

    final result = img.Image(width: src.width, height: src.height);
    for (final p in src) {
      final l = p.r.toInt();
      if (l > threshold) {
        result.setPixelRgba(p.x, p.y, 255, 255, 255, 255);
      } else {
        result.setPixelRgba(p.x, p.y, 0, 0, 0, 255);
      }
    }
    return result;
  }

  static Future<String> _saveTemp(img.Image image, String prefix) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}${Platform.pathSeparator}$prefix${DateTime.now().millisecondsSinceEpoch}.jpg';
    final jpg = img.encodeJpg(image, quality: 90);
    await File(path).writeAsBytes(jpg);
    return path;
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
