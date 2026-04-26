import 'dart:async';
import 'package:flutter/foundation.dart';

import '../services/local_notification_service.dart';
import '../services/yamnet_audio_service.dart';

class SoundMessage {
  final String label;
  final double score;
  final DateTime time;

  SoundMessage({required this.label, required this.score, required this.time});
}

class SoundDetectionViewModel extends ChangeNotifier {
  final YamnetAudioService _service = YamnetAudioService();
  StreamSubscription? _sub;

  bool _isListening = false;
  String _lastLabel = 'No sound';
  double _lastScore = 0.0;

  final List<SoundMessage> _messages = [];

  bool get isListening => _isListening;
  String get lastLabel => _lastLabel;
  double get lastScore => _lastScore;
  List<SoundMessage> get messages => List.unmodifiable(_messages);

  Future<void> start() async {
    if (_isListening) return;

    await _sub?.cancel();

    _sub = _service.results.listen((result) async {
      _lastLabel = result.label;
      _lastScore = result.score;

      // مهم: سجل أي detection دلوقتي بدون فلترة
      _messages.insert(
        0,
        SoundMessage(
          label: result.label,
          score: result.score,
          time: DateTime.now(),
        ),
      );

      await LocalNotificationService.showSoundAlert(
        title: 'Sound detected',
        body: '${result.label} (${result.score.toStringAsFixed(2)})',
      );

      notifyListeners();
    });

    await _service.start();
    _isListening = true;
    notifyListeners();
  }

  Future<void> stop() async {
    await _service.stop();
    await _sub?.cancel();
    _sub = null;
    _isListening = false;
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
