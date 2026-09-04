import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class OcrService {
  static final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  static const _maxRetries = 3;
  static const _minImageWidth = 1000;
  static const _borderWidth = 10;

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
      debugPrint("OcrService.scanDocument error: $e");
    }
    return null;
  }

  /// Ekstrak teks dengan 4 pass: original → contrast → binarize → combined
  static Future<String> extractText(String imagePath) async {
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      String path = imagePath;

      if (attempt == 1) {
        final p = await _preprocessContrast(imagePath);
        if (p != null) path = p;
      } else if (attempt == 2) {
        final p = await _preprocessBinarize(imagePath);
        if (p != null) path = p;
      } else if (attempt == 3) {
        final p = await _preprocessCombined(imagePath);
        if (p != null) path = p;
      }

      try {
        final inputImage = InputImage.fromFilePath(path);
        final recognizedText = await _textRecognizer.processImage(inputImage);
        final text = recognizedText.text.trim();

        if (_hasReadableText(text)) {
          return text;
        }
      } catch (e) {
        debugPrint("OcrService.extractText attempt $attempt error: $e");
      }
    }

    return "";
  }

  /// Validasi: minimal ada 1 angka yang terbaca (bukan sekadar noise)
  static bool _hasReadableText(String text) {
    if (text.isEmpty) return false;
    return RegExp(r'\d').hasMatch(text);
  }

  /// Upscale otomatis: jika gambar < 1000px, resize 2x
  /// Karakter minimal 16x16px untuk MLKit
  static img.Image _ensureMinWidth(img.Image original) {
    if (original.width >= _minImageWidth) return original;
    final scale = _minImageWidth / original.width;
    return img.resize(original,
        width: (original.width * scale).toInt(),
        height: (original.height * scale).toInt(),
        interpolation: img.Interpolation.linear);
  }

  /// Tambahkan white border (10px) di tepi gambar
  /// Mencegah MLKit salah crop edge detection
  static img.Image _addWhiteBorder(img.Image src) {
    final result = img.Image(
      width: src.width + _borderWidth * 2,
      height: src.height + _borderWidth * 2,
    );
    // Fill putih dulu
    img.fill(result, color: img.ColorRgba8(255, 255, 255, 255));
    // Composite gambar asal di tengah
    img.compositeImage(result, src, dstX: _borderWidth, dstY: _borderWidth);
    return result;
  }

  /// Pass 1: grayscale + kontras + sharpen
  static Future<String?> _preprocessContrast(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) return null;

      final prepared = _addWhiteBorder(_ensureMinWidth(original));
      final gray = img.grayscale(prepared);
      final enhanced = img.adjustColor(gray, contrast: 1.8, brightness: 0.05);
      final sharp = img.convolution(enhanced, filter: [
        -1, -1, -1,
        -1,  9, -1,
        -1, -1, -1,
      ], div: 1, offset: 0);

      return await _saveTemp(sharp, 'contrast_');
    } catch (e) {
      debugPrint("OcrService._preprocessContrast error: $e");
      return null;
    }
  }

  /// Pass 2: binarization (hitam-putih tegas) untuk thermal paper
  static Future<String?> _preprocessBinarize(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) return null;

      final prepared = _addWhiteBorder(_ensureMinWidth(original));
      final gray = img.grayscale(prepared);
      // Noise reduction: Gaussian blur ringan sebelum binarization
      final blurred = img.gaussianBlur(gray, radius: 1);
      final bw = _adaptiveThreshold(blurred);
      final sharp = img.convolution(bw, filter: [
        -1, -1, -1,
        -1,  9, -1,
        -1, -1, -1,
      ], div: 1, offset: 0);

      return await _saveTemp(sharp, 'bw_');
    } catch (e) {
      debugPrint("OcrService._preprocessBinarize error: $e");
      return null;
    }
  }

  /// Pass 4: combined preprocessing — grayscale + contrast + binarize sekaligus
  static Future<String?> _preprocessCombined(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) return null;

      final prepared = _addWhiteBorder(_ensureMinWidth(original));
      final gray = img.grayscale(prepared);
      final blurred = img.gaussianBlur(gray, radius: 1);
      final bw = _adaptiveThreshold(blurred);
      final enhanced = img.adjustColor(bw, contrast: 1.5, brightness: 0.0);
      final sharp = img.convolution(enhanced, filter: [
        -1, -1, -1,
        -1,  9, -1,
        -1, -1, -1,
      ], div: 1, offset: 0);

      return await _saveTemp(sharp, 'combined_');
    } catch (e) {
      debugPrint("OcrService._preprocessCombined error: $e");
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
