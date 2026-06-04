import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  static final SpeechService _instance = SpeechService._();
  factory SpeechService() => _instance;

  SpeechService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize();
    return _isInitialized;
  }

  Future<bool> requestPermission() async {
    if (_isInitialized) return true;
    return initialize();
  }

  Future<void> startListening({
    required void Function(String text) onResult,
    void Function(String? error)? onError,
  }) async {
    if (_isListening) return;

    if (!_isInitialized) {
      onError?.call('Speech-to-text belum diinisialisasi');
      return;
    }

    _isListening = true;
    await _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          onResult(result.recognizedWords);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: 'id_ID',
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      ),
    );
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;
    await _speech.stop();
  }

  void dispose() {
    _speech.stop();
  }
}
