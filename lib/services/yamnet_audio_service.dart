import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_litert/flutter_litert.dart';
import 'package:record/record.dart';
import 'yamnet_labels.dart';

class DetectionResult {
  final String label;
  final double score;

  DetectionResult({required this.label, required this.score});
}

class YamnetAudioService {
  final AudioRecorder _recorder = AudioRecorder();

  Interpreter? _interpreter;
  List<String> _labels = [];

  StreamSubscription<Uint8List>? _audioSub;
  final _controller = StreamController<DetectionResult>.broadcast();

  Stream<DetectionResult> get results => _controller.stream;

  final ListQueue<double> _buffer = ListQueue<double>();

  static const int sampleRate = 16000;
  static const int windowSize = 6144;
  static const int hopSize = 3072; // 0.48 sec

  int _samplesSinceLastInference = 0;
  bool _isRunningInference = false;
  bool _printedChunkOnce = false;

  Future<void> init() async {
    debugPrint('YAMNET: init start');

    // مهم: حمّل من الـ asset key
    final data = await rootBundle.load('assets/models/yamnet.tflite');
    debugPrint('YAMNET: model bytes = ${data.lengthInBytes}');

    _interpreter ??= await Interpreter.fromAsset('assets/models/yamnet.tflite');

    final inputTensors = _interpreter!.getInputTensors();
    final outputTensors = _interpreter!.getOutputTensors();

    debugPrint('YAMNET: input tensors count = ${inputTensors.length}');
    for (int i = 0; i < inputTensors.length; i++) {
      debugPrint(
        'YAMNET: input[$i] shape=${inputTensors[i].shape} type=${inputTensors[i].type}',
      );
    }

    debugPrint('YAMNET: output tensors count = ${outputTensors.length}');
    for (int i = 0; i < outputTensors.length; i++) {
      debugPrint(
        'YAMNET: output[$i] shape=${outputTensors[i].shape} type=${outputTensors[i].type}',
      );
    }

    if (_labels.isEmpty) {
      _labels = await YamnetLabels.load();
      debugPrint('YAMNET: labels loaded = ${_labels.length}');
    }

    debugPrint('YAMNET: init done');
  }

  Future<void> start() async {
    await init();

    final hasPermission = await _recorder.hasPermission();
    debugPrint('YAMNET: mic permission = $hasPermission');

    if (!hasPermission) {
      throw Exception('Microphone permission denied');
    }

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
      ),
    );

    debugPrint('YAMNET: stream started');

    _audioSub = stream.listen(
      _onAudioChunk,
      onError: (e, st) {
        debugPrint('YAMNET STREAM ERROR: $e');
        debugPrint('$st');
      },
    );
  }

  Future<void> stop() async {
    debugPrint('YAMNET: stop');
    await _audioSub?.cancel();
    _audioSub = null;
    await _recorder.stop();
    _buffer.clear();
    _samplesSinceLastInference = 0;
    _printedChunkOnce = false;
  }

  Future<void> dispose() async {
    await stop();
    _interpreter?.close();
    _interpreter = null;
    await _controller.close();
    _recorder.dispose();
  }

  void _onAudioChunk(Uint8List chunk) {
    if (!_printedChunkOnce) {
      debugPrint('YAMNET: first audio chunk bytes = ${chunk.length}');
      _printedChunkOnce = true;
    }

    final samples = _pcm16ToFloat32(chunk);

    for (final s in samples) {
      _buffer.addLast(s);
      if (_buffer.length > windowSize) {
        _buffer.removeFirst();
      }
      _samplesSinceLastInference++;
    }

    if (_buffer.length == windowSize &&
        _samplesSinceLastInference >= hopSize &&
        !_isRunningInference) {
      _samplesSinceLastInference = 0;
      _runInference(List<double>.from(_buffer));
    }
  }

  List<double> _pcm16ToFloat32(Uint8List bytes) {
    final bd = ByteData.sublistView(bytes);
    final out = <double>[];

    for (int i = 0; i < bytes.length; i += 2) {
      final sample = bd.getInt16(i, Endian.little);
      out.add(sample / 32768.0);
    }

    return out;
  }

  Future<void> _runInference(List<double> waveform) async {
    _isRunningInference = true;

    try {
      debugPrint('YAMNET: running inference, samples=${waveform.length}');

      final input = Float32List.fromList(waveform);

      final outputTensors = _interpreter!.getOutputTensors();
      final scoresShape = outputTensors[0].shape;
      final embeddingsShape = outputTensors.length > 1
          ? outputTensors[1].shape
          : [1, 1024];
      final spectrogramShape = outputTensors.length > 2
          ? outputTensors[2].shape
          : [1, 64];

      debugPrint('YAMNET: scoresShape=$scoresShape');
      debugPrint('YAMNET: embeddingsShape=$embeddingsShape');
      debugPrint('YAMNET: spectrogramShape=$spectrogramShape');

      final scores = _create2DDoubleList(scoresShape);
      final embeddings = _create2DDoubleList(embeddingsShape);
      final spectrogram = _create2DDoubleList(spectrogramShape);

      final outputs = <int, Object>{0: scores, 1: embeddings, 2: spectrogram};

      _interpreter!.runForMultipleInputs([input], outputs);

      final scoreFrames = outputs[0] as List;
      if (scoreFrames.isEmpty) {
        debugPrint('YAMNET: empty score frames');
        return;
      }

      final firstFrame = scoreFrames.first as List;
      if (firstFrame.isEmpty) {
        debugPrint('YAMNET: empty first frame');
        return;
      }

      int bestIndex = 0;
      double bestScore = -1;

      for (int i = 0; i < firstFrame.length; i++) {
        final v = (firstFrame[i] as num).toDouble();
        if (v > bestScore) {
          bestScore = v;
          bestIndex = i;
        }
      }

      final label = bestIndex < _labels.length ? _labels[bestIndex] : 'Unknown';

      debugPrint('YAMNET RESULT: $label ($bestScore)');

      _controller.add(DetectionResult(label: label, score: bestScore));
    } catch (e, st) {
      debugPrint('YAMNET ERROR: $e');
      debugPrint('$st');
    } finally {
      _isRunningInference = false;
    }
  }

  List<List<double>> _create2DDoubleList(List<int> shape) {
    if (shape.length != 2) {
      throw Exception('Unsupported tensor shape: $shape');
    }
    return List.generate(shape[0], (_) => List<double>.filled(shape[1], 0.0));
  }
}
