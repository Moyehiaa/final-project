import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_litert/flutter_litert.dart';
import 'package:record/record.dart';

class DetectionResult {
  final String label;
  final double score;

  const DetectionResult({required this.label, required this.score});
}

class SoundClassifierAudioService {
  static const int sampleRate = 16000;

  static const String yamnetModelPath = 'assets/models/yamnet.tflite';
  static const String classifierModelPath =
      'assets/models/sound_classifier.tflite';
  static const String labelsPath = 'assets/models/sound_labels.txt';

  final AudioRecorder _recorder = AudioRecorder();

  Interpreter? _yamnetInterpreter;
  Interpreter? _classifierInterpreter;

  StreamSubscription<Uint8List>? _audioSub;
  final StreamController<DetectionResult> _controller =
      StreamController<DetectionResult>.broadcast();

  final ListQueue<double> _buffer = ListQueue<double>();

  List<String> _labels = [];

  int _windowSize = 15600;
  late int _hopSize;

  int _samplesSinceLastInference = 0;
  bool _isRunningInference = false;
  bool _printedChunkOnce = false;

  Stream<DetectionResult> get results => _controller.stream;

  Future<void> init() async {
    debugPrint('SOUND CLASSIFIER: init start');

    _yamnetInterpreter ??= await Interpreter.fromAsset(yamnetModelPath);
    _classifierInterpreter ??= await Interpreter.fromAsset(classifierModelPath);

    final yamnetInputs = _yamnetInterpreter!.getInputTensors();
    final yamnetOutputs = _yamnetInterpreter!.getOutputTensors();
    final classifierInputs = _classifierInterpreter!.getInputTensors();
    final classifierOutputs = _classifierInterpreter!.getOutputTensors();

    debugPrint('YAMNET input tensors: ${yamnetInputs.length}');
    for (var i = 0; i < yamnetInputs.length; i++) {
      debugPrint(
        'YAMNET input[$i] shape=${yamnetInputs[i].shape} '
        'type=${yamnetInputs[i].type}',
      );
    }

    debugPrint('YAMNET output tensors: ${yamnetOutputs.length}');
    for (var i = 0; i < yamnetOutputs.length; i++) {
      debugPrint(
        'YAMNET output[$i] shape=${yamnetOutputs[i].shape} '
        'type=${yamnetOutputs[i].type}',
      );
    }

    debugPrint('CLASSIFIER input tensors: ${classifierInputs.length}');
    for (var i = 0; i < classifierInputs.length; i++) {
      debugPrint(
        'CLASSIFIER input[$i] shape=${classifierInputs[i].shape} '
        'type=${classifierInputs[i].type}',
      );
    }

    debugPrint('CLASSIFIER output tensors: ${classifierOutputs.length}');
    for (var i = 0; i < classifierOutputs.length; i++) {
      debugPrint(
        'CLASSIFIER output[$i] shape=${classifierOutputs[i].shape} '
        'type=${classifierOutputs[i].type}',
      );
    }

    final inputShape = yamnetInputs.first.shape;
    if (inputShape.isNotEmpty && inputShape.last > 0) {
      _windowSize = inputShape.last;
    }

    _hopSize = (_windowSize / 2).round();

    if (_labels.isEmpty) {
      final labelsText = await rootBundle.loadString(labelsPath);
      _labels = labelsText
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      debugPrint('CLASSIFIER labels loaded = ${_labels.length}');
    }

    if (_labels.length != 10) {
      throw Exception(
        'sound_labels.txt must contain exactly 10 labels. '
        'Current count: ${_labels.length}',
      );
    }

    debugPrint(
      'SOUND CLASSIFIER: init done, windowSize=$_windowSize, hopSize=$_hopSize',
    );
  }

  Future<void> start() async {
    await init();

    final hasPermission = await _recorder.hasPermission();
    debugPrint('SOUND CLASSIFIER: mic permission = $hasPermission');

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

    debugPrint('SOUND CLASSIFIER: stream started');

    _audioSub = stream.listen(
      _onAudioChunk,
      onError: (e, st) {
        debugPrint('SOUND CLASSIFIER STREAM ERROR: $e');
        debugPrint('$st');
      },
    );
  }

  Future<void> stop() async {
    debugPrint('SOUND CLASSIFIER: stop');

    await _audioSub?.cancel();
    _audioSub = null;

    await _recorder.stop();

    _buffer.clear();
    _samplesSinceLastInference = 0;
    _printedChunkOnce = false;
    _isRunningInference = false;
  }

  Future<void> dispose() async {
    await stop();

    _yamnetInterpreter?.close();
    _classifierInterpreter?.close();

    _yamnetInterpreter = null;
    _classifierInterpreter = null;

    await _controller.close();
    _recorder.dispose();
  }

  void _onAudioChunk(Uint8List chunk) {
    if (!_printedChunkOnce) {
      debugPrint('SOUND CLASSIFIER: first audio chunk bytes = ${chunk.length}');
      _printedChunkOnce = true;
    }

    final samples = _pcm16ToFloat32(chunk);

    for (final sample in samples) {
      _buffer.addLast(sample);

      if (_buffer.length > _windowSize) {
        _buffer.removeFirst();
      }

      _samplesSinceLastInference++;
    }

    if (_buffer.length == _windowSize &&
        _samplesSinceLastInference >= _hopSize &&
        !_isRunningInference) {
      _samplesSinceLastInference = 0;
      _runInference(List<double>.from(_buffer));
    }
  }

  List<double> _pcm16ToFloat32(Uint8List bytes) {
    final byteData = ByteData.sublistView(bytes);
    final output = <double>[];

    for (var i = 0; i + 1 < bytes.length; i += 2) {
      final sample = byteData.getInt16(i, Endian.little);
      output.add(sample / 32768.0);
    }

    return output;
  }

  Future<void> _runInference(List<double> waveform) async {
    _isRunningInference = true;

    try {
      final embedding = _extractYamnetEmbedding(waveform);
      final result = _runCustomClassifier(embedding);

      debugPrint(
        'CLASSIFIER RESULT: ${result.label} '
        '(${result.score.toStringAsFixed(3)})',
      );

      _controller.add(result);
    } catch (e, st) {
      debugPrint('SOUND CLASSIFIER ERROR: $e');
      debugPrint('$st');
    } finally {
      _isRunningInference = false;
    }
  }

  List<double> _extractYamnetEmbedding(List<double> waveform) {
    final inputShape = _yamnetInterpreter!.getInputTensors().first.shape;
    final outputTensors = _yamnetInterpreter!.getOutputTensors();

    final Object input;

    if (inputShape.length == 2) {
      input = <List<double>>[List<double>.from(waveform)];
    } else {
      input = Float32List.fromList(waveform);
    }

    // الحالة الأولى: YAMNet عنده output واحد فقط
    // غالبًا ده embedding جاهز [1, 1024]
    if (outputTensors.length == 1) {
      final outputShape = outputTensors[0].shape;

      debugPrint('YAMNET single output shape = $outputShape');

      final output = _create2DDoubleList(outputShape);

      _yamnetInterpreter!.run(input, output);

      final firstFrame = output.first;

      if (firstFrame.length != 1024) {
        throw Exception(
          'YAMNet single output is not embedding 1024. '
          'Output shape: $outputShape, length: ${firstFrame.length}',
        );
      }

      return firstFrame;
    }

    // الحالة الثانية: YAMNet الأصلي عنده 3 outputs:
    // scores, embeddings, spectrogram
    final scoresShape = outputTensors[0].shape;
    final embeddingsShape = outputTensors[1].shape;
    final spectrogramShape = outputTensors.length > 2
        ? outputTensors[2].shape
        : <int>[1, 64];

    final scores = _create2DDoubleList(scoresShape);
    final embeddings = _create2DDoubleList(embeddingsShape);
    final spectrogram = _create2DDoubleList(spectrogramShape);

    final outputs = <int, Object>{0: scores, 1: embeddings, 2: spectrogram};

    _yamnetInterpreter!.runForMultipleInputs([input], outputs);

    final embeddingFrames = outputs[1] as List<List<double>>;

    if (embeddingFrames.isEmpty) {
      throw Exception('YAMNet returned empty embeddings');
    }

    return _averageEmbeddingFrames(embeddingFrames);
  }

  DetectionResult _runCustomClassifier(List<double> embedding) {
    final input = <List<double>>[embedding];
    final output = List<List<double>>.generate(
      1,
      (_) => List<double>.filled(_labels.length, 0.0),
    );

    _classifierInterpreter!.run(input, output);

    final scores = output.first;

    var bestIndex = 0;
    var bestScore = scores.first;

    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > bestScore) {
        bestScore = scores[i];
        bestIndex = i;
      }
    }

    return DetectionResult(label: _labels[bestIndex], score: bestScore);
  }

  List<double> _averageEmbeddingFrames(List<List<double>> frames) {
    final embeddingSize = frames.first.length;
    final average = List<double>.filled(embeddingSize, 0.0);

    for (final frame in frames) {
      for (var i = 0; i < embeddingSize; i++) {
        average[i] += frame[i];
      }
    }

    for (var i = 0; i < embeddingSize; i++) {
      average[i] /= frames.length;
    }

    return average;
  }

  List<List<double>> _create2DDoubleList(List<int> shape) {
    if (shape.length != 2) {
      throw Exception('Unsupported tensor shape: $shape');
    }

    return List<List<double>>.generate(
      shape[0],
      (_) => List<double>.filled(shape[1], 0.0),
    );
  }
}
