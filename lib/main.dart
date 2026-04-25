import 'package:flutter/material.dart';
import 'services/local_notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.init();
  runApp(const Sound2SignApp());
}
