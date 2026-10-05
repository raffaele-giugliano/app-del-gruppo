import 'package:flutter/material.dart';
import '../models/app_config.dart';
import '../services/csv_service.dart';
import '../widgets/loading_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AppConfig _config;
  late CsvService _csvService;
  
  bool _isLoading = true;
  String? _errorMessage;
  String? _csvRawContent;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  void _initAndLoad() async {
    final Uri currentUri = Uri.base;
    final String groupParam = currentUri.queryParameters['group'] ?? '';

    _config = AppConfig(groupName: groupParam);
    _csvService = CsvService(backendUrl: _config.backendBaseUrl);

    if (!_config.hasGroup) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Nessun gruppo specificato nell\'URL.\nEsempio: ?group=nomegruppo';
      });
      return;
    }

    try {
      final data = await _csvService.fetchGuideSheet(_config.groupName);
      setState(() {
        _csvRawContent = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_config.hasGroup ? 'Gruppo: ${_config.groupName}' : 'App Gruppi'),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _errorMessage != null
              ? LoadingWidget(errorMessage: _errorMessage)
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Dati scaricati dal BE:\n\n$_csvRawContent'),
                  ),
                ),
    );
  }
}