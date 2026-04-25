import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/local_notification_service.dart';
import '../services/yamnet_audio_service.dart';

class SoundDetectionViewModel extends ChangeNotifier {
  final YamnetAudioService _service = YamnetAudioService();

  StreamSubscription? _sub;
  bool _isListening = false;
  String _lastLabel = 'No sound';
  double _lastScore = 0.0;
  DateTime? _lastNotificationAt;

  bool get isListening => _isListening;
  String get lastLabel => _lastLabel;
  double get lastScore => _lastScore;

  final importantKeywords = <String>[
    'alarm',
    'siren',
    'speech',
    'cry',
    'dog',
    'bell',
    'knock',
  ];

  Future<void> start() async {
    if (_isListening) return;

    _sub = _service.results.listen((result) async {
      _lastLabel = result.label;
      _lastScore = result.score;
      notifyListeners();

      if (_shouldNotify(result.label, result.score)) {
        await LocalNotificationService.showSoundAlert(
          title: 'Sound detected',
          body: '${result.label} (${result.score.toStringAsFixed(2)})',
        );
        _lastNotificationAt = DateTime.now();
      }
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

  Future<void> disposeService() async {
    await _service.dispose();
  }

  bool _shouldNotify(String label, double score) {
    if (score < 0.65) return false;

    final lower = label.toLowerCase();
    final important = importantKeywords.any((k) => lower.contains(k));
    if (!important) return false;

    if (_lastNotificationAt == null) return true;
    return DateTime.now().difference(_lastNotificationAt!).inSeconds >= 5;
  }
}
