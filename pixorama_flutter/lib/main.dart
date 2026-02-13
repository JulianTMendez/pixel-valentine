import 'package:pixorama_client/pixorama_client.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

import 'config/app_config.dart';
import 'src/pixorama.dart';

late Client client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String apiUrl = 'https://lesser-annabela-victorymonk-b48468b1.koyeb.app/';

  try {
    // Load configuration (API URL) from assets/config.json
    final config = await AppConfig.loadConfig();
    if (config.apiUrl != null) {
      apiUrl = config.apiUrl!;
      if (!apiUrl.endsWith('/')) {
        apiUrl = '$apiUrl/';
      }
    }
  } catch (e) {
    debugPrint('Error loading config: $e');
  }

  client = Client(apiUrl)..connectivityMonitor = FlutterConnectivityMonitor();
  debugPrint('Connecting to Serverpod at: $apiUrl');

  runApp(const PixoramaApp());
}

class PixoramaApp extends StatelessWidget {
  const PixoramaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixorama',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Scaffold(
        body: Pixorama(),
      ),
    );
  }
}
