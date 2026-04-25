import 'package:flutter/services.dart' show rootBundle;

class YamnetLabels {
  static Future<List<String>> load() async {
    final csv = await rootBundle.loadString(
      'assets/models/yamnet_class_map.csv',
    );
    final lines = csv.split('\n').where((e) => e.trim().isNotEmpty).toList();

    // غالبًا أول سطر header
    final labels = <String>[];
    for (int i = 1; i < lines.length; i++) {
      final parts = lines[i].split(',');
      if (parts.isNotEmpty) {
        labels.add(parts.last.trim().replaceAll('"', ''));
      }
    }
    return labels;
  }
}
