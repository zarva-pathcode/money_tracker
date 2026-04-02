import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class _ImageProcessingArgs {
  final String inputPath;
  final String outputPath;

  _ImageProcessingArgs(this.inputPath, this.outputPath);
}

class ImagePreprocessor {
  /// Fungsi utama yang memproses gambar struk murni di belakang layar.
  /// Fungsi ini menerapkan OpenCV Pipeline (Grayscale -> Sharpen -> Threshold)
  /// lalu mengembalikan path string dari gambar hasil olahan.
  static Future<String> processReceiptImage(String inputImagePath) async {
    // Siapkan alamat direktori sementara (Temporary) secara aman dari Main Thread
    final Directory tempDir = await getTemporaryDirectory();
    final String outputPath = "${tempDir.path}/ocr_preprocessed_${DateTime.now().millisecondsSinceEpoch}.jpg";

    // Lempar proses berat (OpenCV FFI C++) ke Isolate terpisah menggunakan `compute`.
    // Ini sangat penting agar UI (loading animation) tidak "Freeze/Lag" selama 1-2 detik.
    return await compute(_processImageIsolate, _ImageProcessingArgs(inputImagePath, outputPath));
  }

  /// Worker function yang dieksekusi oleh Background Isolate
  static Future<String> _processImageIsolate(_ImageProcessingArgs args) async {
    try {
      // 1. Load Image: Baca file gambar dari path asli
      cv.Mat img = cv.imread(args.inputPath);
      if (img.isEmpty) {
        throw Exception("Gagal membaca gambar dari ${args.inputPath}");
      }

      // 2. Grayscale: Konversi gambar warna (BGR) menjadi Hitam-Putih
      cv.Mat gray = cv.cvtColor(img, cv.COLOR_BGR2GRAY);

      // 3. Penajaman (Sharpening) yang Lebih Halus: 
      // Kita kurangi intensitas kernel agar tidak terlalu kasar ('crunchy').
      // Nilai tengah dikurangi dan nilai sekitar disesuaikan agar total tetap 1.
      final kernel = cv.Mat.fromList(3, 3, cv.MatType.CV_32FC1, [
        0.0, -0.5,  0.0,
       -0.5,  3.0, -0.5,
        0.0, -0.5,  0.0,
      ]);
      cv.Mat sharpened = cv.filter2D(gray, -1, kernel);

      // 4. Smoothing Ringan:
      // Menambahkan Gaussian Blur halus (3x3) untuk mengurangi 'noise' 
      // dan membuat tepian huruf lebih lembut/natural sebelum threshold.
      cv.Mat blurred = cv.gaussianBlur(sharpened, (3, 3), 0);

      // 5. Adaptive Thresholding (Gaussian C)
      // Kita tingkatkan nilai konstanta C menjadi 10 (dari sebelumnya 3).
      // Ini akan membuat transisi antara teks dan latar belakang lebih halus 
      // dan mempertahankan detail huruf yang tipis/pudar agar tidak hilang.
      cv.Mat thresholded = cv.adaptiveThreshold(
        blurred, 
        255, 
        cv.ADAPTIVE_THRESH_GAUSSIAN_C, 
        cv.THRESH_BINARY, 
        15, 
        10,
      );

      // 6. Save to Temp: Simpan gambar yang sudah lebih natural ini
      cv.imwrite(args.outputPath, thresholded);

      // Dispose manual menghindari memory leak di memory FFI C++
      img.dispose();
      gray.dispose();
      kernel.dispose();
      sharpened.dispose();
      blurred.dispose();
      thresholded.dispose();

      // Kembalikan path output
      return args.outputPath;

    } catch (e) {
      debugPrint("OpenCV Error: $e");
      // Jika error, kembalikan saja gambar aslinya daripada sistem hancur
      return args.inputPath;
    }
  }
}

/* 
=====================================================
  CONTOH KECIL CARA MEMANGGIL FUNGSI INI DI ML KIT:
=====================================================

  // 1. Ambil foto asli dari image_picker
  final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
  
  if (pickedFile != null) {
      // Jangan lupa setState `isProcessing = true` agar `CircularProgressIndicator` jalan
      // ...
      
      // 2. Bersihkan & Pertajam Gambar!
      String processedPath = await ImagePreprocessor.processReceiptImage(pickedFile.path);
      
      // 3. Daftarkan gambar yang MENGKILAP ini ke Google ML Kit 🤓
      final InputImage inputImage = InputImage.fromFilePath(processedPath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // 4. Baru dilanjutkan ke ReceiptParser mu...
      // ...
  }
*/
