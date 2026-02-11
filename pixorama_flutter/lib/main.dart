import 'package:pixorama_client/pixorama_client.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

import 'config/app_config.dart';
import 'src/pixorama.dart';

late Client client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load configuration (API URL) from assets/config.json
  final config = await AppConfig.loadConfig();
  final apiUrl = config.apiUrl ?? 'http://localhost:8080/';

  client = Client(apiUrl)..connectivityMonitor = FlutterConnectivityMonitor();

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
