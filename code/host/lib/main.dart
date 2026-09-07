import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/caregiver/sign_in_screen.dart';
import 'src/host_flow_state.dart';
import 'src/phone_frame.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const HostApp());
}

class HostApp extends StatefulWidget {
  const HostApp({super.key});

  @override
  State<HostApp> createState() => _HostAppState();
}

class _HostAppState extends State<HostApp> {
  final HostFlowState _flowState = HostFlowState();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tesseract',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          colorSchemeSeed: const Color(0xFF2E7D5B), useMaterial3: true),
      home: SignInScreen(flowState: _flowState),
      builder: (BuildContext context, Widget? child) {
        if (!kIsWeb || child == null) {
          return child ?? const SizedBox.shrink();
        }
        return WebPreviewFrame(
            mediaQueryData: MediaQuery.of(context), child: child);
      },
    );
  }
}
