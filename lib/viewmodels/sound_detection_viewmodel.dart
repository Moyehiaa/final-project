import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/alert_firestore_service.dart';
import '../services/local_notification_service.dart';
import '../services/sound_classifier_audio_service.dart';

class SoundMessage {
  final String label;
  final double score;
  final DateTime time;

  const SoundMessage({
    required this.label,
    required this.score,
    required this.time,
  });
}

class SoundDetectionViewModel extends ChangeNotifier {
  final SoundClassifierAudioService _service = SoundClassifierAudioService();
  final AlertFirestoreService _alertFirestoreService = AlertFirestoreService();

  StreamSubscription<DetectionResult>? _sub;

  bool _isListening = false;
  String _lastLabel = 'No sound';
  double _lastScore = 0.0;

  String? _deafUserId;
  String? _deafUserName;
  String? _caregiverId;

  final List<SoundMessage> _messages = [];
  final Map<String, DateTime> _lastNotificationTimes = {};

  String? _pendingLabel;
  int _pendingCount = 0;
  DateTime? _lastPendingTime;

  static const int requiredRepeatedDetections = 3;
  static const Duration repeatWindow = Duration(seconds: 6);
  static const Duration notificationCooldown = Duration(seconds: 10);

  static const Map<String, double> soundThresholds = {
    'alarm': 0.60,
    'baby_cry': 0.60,
    'bell': 0.60,
    'dog': 0.65,
    'glass_breaking': 0.55,
    'knock': 0.65,
    'phone_ring': 0.60,
    'siren': 0.60,
    'speech': 0.70,
  };

  bool get isListening => _isListening;
  String get lastLabel => _lastLabel;
  double get lastScore => _lastScore;
  List<SoundMessage> get messages => List.unmodifiable(_messages);

  void configureUser({
    required String deafUserId,
    required String deafUserName,
    String? caregiverId,
  }) {
    _deafUserId = deafUserId;
    _deafUserName = deafUserName;
    _caregiverId = caregiverId;
  }

  Future<void> start() async {
    if (_isListening) return;

    await _sub?.cancel();

    _sub = _service.results.listen((result) async {
      _lastLabel = result.label;
      _lastScore = result.score;

      notifyListeners();

      if (!_isImportantResult(result)) {
        _resetPendingDetection();
        return;
      }

      final confirmed = _registerRepeatedDetection(result.label);

      debugPrint(
        'REPEAT CHECK: ${result.label} count=$_pendingCount '
        'required=$requiredRepeatedDetections confirmed=$confirmed',
      );

      if (!confirmed) {
        return;
      }

      if (!_canNotifyNow(result.label)) {
        _resetPendingDetection();
        return;
      }

      _lastNotificationTimes[result.label] = DateTime.now();

      final message = SoundMessage(
        label: result.label,
        score: result.score,
        time: DateTime.now(),
      );

      _messages.insert(0, message);

      await LocalNotificationService.showSoundAlert(
        label: result.label,
        confidence: result.score,
      );

      await _sendAlertToCaregiver(result);

      _resetPendingDetection();

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
    _resetPendingDetection();

    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  Future<void> _sendAlertToCaregiver(DetectionResult result) async {
    final deafUserId = _deafUserId;
    final deafUserName = _deafUserName;
    final caregiverId = _caregiverId;

    if (deafUserId == null || deafUserName == null) {
      debugPrint('ALERT FIRESTORE: missing deaf user data');
      return;
    }

    if (caregiverId == null || caregiverId.isEmpty) {
      debugPrint('ALERT FIRESTORE: no caregiver linked');
      return;
    }

    try {
      await _alertFirestoreService.sendAlertToCaregiver(
        deafUserId: deafUserId,
        deafUserName: deafUserName,
        caregiverId: caregiverId,
        soundType: result.label,
        confidence: result.score,
      );

      debugPrint('ALERT FIRESTORE: sent ${result.label} to caregiver');
    } catch (e, st) {
      debugPrint('ALERT FIRESTORE ERROR: $e');
      debugPrint('$st');
    }
  }

  bool _isImportantResult(DetectionResult result) {
    if (result.label == 'other') {
      return false;
    }

    final threshold = soundThresholds[result.label];

    if (threshold == null) {
      return false;
    }

    return result.score >= threshold;
  }

  bool _registerRepeatedDetection(String label) {
    final now = DateTime.now();

    final isSameLabel = _pendingLabel == label;
    final isInsideWindow = _lastPendingTime == null
        ? true
        : now.difference(_lastPendingTime!) <= repeatWindow;

    if (isSameLabel && isInsideWindow) {
      _pendingCount++;
    } else {
      _pendingLabel = label;
      _pendingCount = 1;
    }

    _lastPendingTime = now;

    return _pendingCount >= requiredRepeatedDetections;
  }

  void _resetPendingDetection() {
    _pendingLabel = null;
    _pendingCount = 0;
    _lastPendingTime = null;
  }

  bool _canNotifyNow(String label) {
    final lastTime = _lastNotificationTimes[label];

    if (lastTime == null) {
      return true;
    }

    return DateTime.now().difference(lastTime) >= notificationCooldown;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
