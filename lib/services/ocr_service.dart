import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Tahap 1: Membuka Kamera dengan Google ML Kit Document Scanner
  /// Menggunakan ScannerMode.filter untuk menjernihkan teks secara otomatis
  static Future<String?> scanDocument() async {
    try {
      final scanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormats: {DocumentFormat.jpeg},
          mode: ScannerMode.full, // Menggunakan mode full untuk auto-crop otomatis
          pageLimit: 1,
          isGalleryImport: true,
        ),
      );

      final DocumentScanningResult response = await scanner.scanDocument();
      scanner.close();

      if (response.images != null && response.images!.isNotEmpty) {
        return response.images!.first;
      }
    } catch (e) {
      print("OCR Service Error (Scan): $e");
    }
    return null;
  }

  /// Tahap 2: Ekstraksi Teks menggunakan ML Kit Text Recognition
  static Future<String> extractText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      print("OCR Service Error (Recognition): $e");
      return "";
    }
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
