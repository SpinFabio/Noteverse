import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

void main() => runApp(const NoteverseApp());

class NoteverseApp extends StatelessWidget {
  const NoteverseApp({super.key, this.client});

  /// Optional HTTP client for testing the setup screen without a running server.
  final http.Client? client;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Noteverse',
    theme: ThemeData(colorSchemeSeed: Colors.indigo),
    home: HomePage(client: client),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.client});

  final http.Client? client;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final http.Client _client = widget.client ?? http.Client();
  String _message = 'Premi Test backend per iniziare';
  bool _testing = false;
  String _status = 'Verifica la connessione al backend';
  bool _loading = false;

  @override
  void dispose() {
    if (widget.client == null) _client.close();
    super.dispose();
  }

  Future<void> _testBackend() async {
    setState(() => _testing = true);
    try {
      final response = await _client
          .get(Uri.parse('$apiBaseUrl/api/hello'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Backend returned ${response.statusCode}');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final message = data['message'] as String;
      if (mounted) setState(() => _message = message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Test fallito: backend non disponibile o risposta non valida',
        );
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _checkBackend() async {
    setState(() => _loading = true);
    try {
      final response = await _client
          .get(Uri.parse('$apiBaseUrl/health/ready'))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _status = response.statusCode == 200
            ? 'Backend e Neo4j connessi'
            : 'Backend attivo, Neo4j non disponibile';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Backend non raggiungibile');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Noteverse')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hub_outlined, size: 64),
            const SizedBox(height: 16),
            const Text('Le tue note, connesse.'),
            const SizedBox(height: 24),
            Text(_message),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _testing ? null : _testBackend,
              child: Text(_testing ? 'Test in corso…' : 'Test backend'),
            ),
            const SizedBox(height: 24),
            Text(_status),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _checkBackend,
              child: Text(_loading ? 'Connessione…' : 'Verifica connessione'),
            ),
          ],
        ),
      ),
    ),
  );
}
