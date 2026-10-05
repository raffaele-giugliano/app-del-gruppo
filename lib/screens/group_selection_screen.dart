import 'package:flutter/material.dart';
import '../models/page_config.dart';
import '../services/csv_service.dart';
import 'table_view_screen.dart';

class GroupSelectionScreen extends StatefulWidget {
  final String? backendBaseUrl;

  const GroupSelectionScreen({Key? key, this.backendBaseUrl}) : super(key: key);

  @override
  State<GroupSelectionScreen> createState() => _GroupSelectionScreenState();
}

class _GroupSelectionScreenState extends State<GroupSelectionScreen> {
  final TextEditingController _groupController = TextEditingController();
  late final CsvService _csvService;

  bool _isLoading = false;
  bool _isGroupConfirmed = false;
  String? _errorMessage;
  List<PageConfig> _pages = [];
  PageConfig? _selectedPage;

  @override
  void initState() {
    super.initState();
    final url = widget.backendBaseUrl ??
        'https://script.google.com/macros/s/AKfycbwqgA2-32aKByzYv9uM3Nks2p9q0I-U6q0_SXXD_4L0Q-73Amlu100QO5JByy4wT-yE/exec';
    _csvService = CsvService(backendBaseUrl: url);
  }

  Future<void> _searchGroup() async {
    final groupName = _groupController.text.trim();
    if (groupName.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _pages = [];
      _selectedPage = null;
    });

    try {
      final indexCsvUrl = await _csvService.getCsvUrlForGroup(groupName);
      final pages = await _csvService.fetchGroupIndex(indexCsvUrl);

      setState(() {
        _pages = pages;
        _isLoading = false;
        _isGroupConfirmed = true; // Blocca il nome del gruppo
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _isGroupConfirmed = false;
      });
    }
  }

  void _resetGroupSelection() {
    setState(() {
      _isGroupConfirmed = false;
      _pages = [];
      _selectedPage = null;
      _errorMessage = null;
    });
  }

  void _confirmPageSelection() {
    if (_selectedPage == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TableViewScreen(pageConfig: _selectedPage!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selezione Gruppo'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo Testo Nome Gruppo
            TextField(
              controller: _groupController,
              enabled: !_isGroupConfirmed, // Disabilitato quando il gruppo è confermato
              decoration: InputDecoration(
                labelText: 'Nome Gruppo',
                prefixIcon: const Icon(Icons.group),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) {
                if (!_isGroupConfirmed) _searchGroup();
              },
            ),
            const SizedBox(height: 12),

            // Tasto Cerca Gruppo o Tasto Cambia Gruppo con freccia <-
            if (!_isGroupConfirmed)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _searchGroup,
                icon: const Icon(Icons.search),
                label: const Text('CERCA GRUPPO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _resetGroupSelection,
                icon: const Icon(Icons.arrow_back),
                label: const Text('CAMBIA GRUPPO'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              )
            else if (_isGroupConfirmed && _pages.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 16),
              DropdownButtonFormField<PageConfig>(
                decoration: InputDecoration(
                  labelText: 'Seleziona Pagina',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: _selectedPage,
                items: _pages.map((page) {
                  return DropdownMenuItem<PageConfig>(
                    value: page,
                    child: Text(page.pageName),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedPage = val;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Bottone di conferma: disabilitato se _selectedPage == null
              ElevatedButton(
                onPressed: _selectedPage == null ? null : _confirmPageSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _selectedPage == null ? 0 : 3,
                ),
                child: const Text(
                  'CONFERMA SELEZIONE PAGINA',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}