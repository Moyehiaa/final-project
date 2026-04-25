import 'dart:async';
import 'package:flutter/material.dart';
import '../../const.dart';
import '../../widgets/sound_alert_tile.dart';
import '../../widgets/primary_button.dart';
import '../../services/yamnet_audio_service.dart';
import '../../services/local_notification_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _shouldNotify(String label, double score) {
    if (score < 0.4) return false;

    final lower = label.toLowerCase();

    return lower.contains('alarm') ||
        lower.contains('siren') ||
        lower.contains('dog') ||
        lower.contains('speech') ||
        lower.contains('bell') ||
        lower.contains('cry') ||
        lower.contains('knock');
  }

  final YamnetAudioService _audioService = YamnetAudioService();
  StreamSubscription? _subscription;

  bool _isListening = false;
  String _lastLabel = 'No sound';
  double _lastScore = 0.0;

  @override
  void dispose() {
    _subscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    await _audioService.init();

    _subscription?.cancel();
    _subscription = _audioService.results.listen((result) async {
      print('Detected: ${result.label} - ${result.score}');

      if (!mounted) return;

      setState(() {
        _lastLabel = result.label;
        _lastScore = result.score;
      });

      if (_shouldNotify(result.label, result.score)) {
        await LocalNotificationService.showSoundAlert(
          title: 'Sound detected',
          body: '${result.label} (${result.score.toStringAsFixed(2)})',
        );
      }
    });

    await _audioService.start();

    if (!mounted) return;
    setState(() {
      _isListening = true;
    });
  }

  Future<void> _stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    await _audioService.stop();

    if (!mounted) return;
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _toggleListening() async {
    try {
      if (_isListening) {
        await _stopListening();
      } else {
        await _startListening();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kAccent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _isListening
                        ? Icons.graphic_eq_rounded
                        : Icons.mic_off_rounded,
                    color: kAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Listening status",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isListening
                            ? "Listening • Last sound: $_lastLabel (${_lastScore.toStringAsFixed(2)})"
                            : "Paused • Tap the button below to start listening",
                        style: const TextStyle(color: kText2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Recent alerts",
            style: TextStyle(fontWeight: FontWeight.w900, color: kText),
          ),
          const SizedBox(height: 10),
          if (_lastLabel != 'No sound')
            SoundAlertTile(
              icon: _getSoundIcon(_lastLabel),
              title: _lastLabel,
              subtitle:
                  "Detected • Confidence ${_lastScore.toStringAsFixed(2)}",
              time: "Now",
              color: _getSoundColor(_lastLabel),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                "No alerts yet.",
                style: TextStyle(color: kText2),
              ),
            ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: _isListening ? "Pause Listening" : "Start Listening",
            onPressed: _toggleListening,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kDanger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kDanger.withOpacity(0.18)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_rounded, color: kDanger),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "SOS is always available for emergencies.",
                    style: TextStyle(color: kText2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSoundIcon(String label) {
    final lower = label.toLowerCase();

    if (lower.contains('alarm')) return Icons.local_fire_department_rounded;
    if (lower.contains('siren')) return Icons.emergency_rounded;
    if (lower.contains('dog')) return Icons.pets_rounded;
    if (lower.contains('speech')) return Icons.record_voice_over_rounded;
    if (lower.contains('bell')) return Icons.notifications_active_rounded;
    if (lower.contains('cry')) return Icons.child_care_rounded;

    return Icons.multitrack_audio_rounded;
  }

  Color _getSoundColor(String label) {
    final lower = label.toLowerCase();

    if (lower.contains('alarm') || lower.contains('siren')) return kDanger;
    if (lower.contains('bell')) return const Color(0xFF3A7BD5);
    if (lower.contains('dog')) return Colors.orange;
    if (lower.contains('speech')) return Colors.green;

    return kAccent;
  }
}
