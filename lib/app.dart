import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sound2sign/viewmodels/sound_detection_viewmodel.dart';
import 'const.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/onboarding/onboarding_view.dart';

class Sound2SignApp extends StatelessWidget {
  const Sound2SignApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => SoundDetectionViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Sound2Sign",
        theme: ThemeData(
          scaffoldBackgroundColor: kBg,
          colorScheme: ColorScheme.fromSeed(seedColor: kPrimary),
          useMaterial3: true,
        ),
        home: const OnboardingView(),
      ),
    );
  }
}
