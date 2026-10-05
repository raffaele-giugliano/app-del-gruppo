import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/csv_service.dart';
import '../models/page_config.dart';

class GroupSelectionScreen extends StatefulWidget {
  final String backendBaseUrl;

  const GroupSelectionScreen({
    Key? key,
    required this.backendBaseUrl,
  }) : super(key: key);

  @override
  State<GroupSelectionScreen> createState() => _GroupSelectionScreenState();
}

class _GroupSelectionScreenState extends State<GroupSelectionScreen> {
  final TextEditingController _groupController = TextEditingController();
  final StorageService _storageService = StorageService();

  String? _savedGroup;
  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;

  List<PageConfig> _availablePages = [];
  PageConfig? _selectedPage;

  @override
  void initState() {
    super.initState();
    _checkSavedGroup();
  }

  Future<void> _checkSavedGroup() async {
    final group = await _storageService.getSavedGroup();
    setState(() {
      _savedGroup = group;
      if (group != null) {
        _groupController.text = group;
      }
      _isLoading = false;
    });

    if (group != null) {
      _loadGroupData(group);
    }
  }

  Future<void> _loadGroupData(String groupName) async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _availablePages = [];
      _selectedPage = null;
    });

    try {
      final csvService = CsvService(backendBaseUrl: widget.backendBaseUrl);
      final indexCsvUrl = await csvService.getCsvUrlForGroup(groupName);
      final pages = await csvService.fetchGroupIndex(indexCsvUrl);

      await _storageService.saveGroup(groupName);

      if (!mounted) return;

      setState(() {
        _savedGroup = groupName;
        _availablePages = pages;
        if (pages.isNotEmpty) {
          _selectedPage = pages.first;
        }
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossibile recuperare i dati del gruppo.';
        _isSearching = false;
      });
    }
  }

  Future<void> _resetGroup() async {
    await _storageService.clearGroup();
    setState(() {
      _savedGroup = null;
      _groupController.clear();
      _errorMessage = null;
      _availablePages = [];
      _selectedPage = null;
    });
  }

  void _confirmPageSelection() {
    if (_selectedPage == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pagina selezionata: ${_selectedPage!.pageName} (${_selectedPage!.tables.length} tabelle collegate)',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accesso Gruppo'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.groups_rounded,
                  size: 80,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 24),

                if (_savedGroup != null) ...[
                  Text(
                    'Gruppo Memorizzato:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _savedGroup!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isSearching) ...[
                    const Center(child: CircularProgressIndicator()),
                  ] else if (_availablePages.isNotEmpty) ...[
                    DropdownButtonFormField<PageConfig>(
                      value: _selectedPage,
                      decoration: InputDecoration(
                        labelText: 'Seleziona Pagina',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.web_rounded),
                      ),
                      items: _availablePages.map((page) {
                        return DropdownMenuItem<PageConfig>(
                          value: page,
                          child: Text(page.pageName),
                        );
                      }).toList(),
                      onChanged: (PageConfig? newPage) {
                        setState(() {
                          _selectedPage = newPage;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _confirmPageSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'CONFERMA SELEZIONE PAGINA',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Nessuna pagina disponibile per questo gruppo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red),
                    ),
                  ],

                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _resetGroup,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cambia Gruppo'),
                  ),
                ] else ...[
                  const Text(
                    'Inserisci il nome del tuo gruppo per accedere al calendario ed alle informazioni dedicate.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _groupController,
                    decoration: InputDecoration(
                      labelText: 'Nome Gruppo',
                      hintText: 'La_mia_squadra', // <--- Aggiornato Hint
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.search),
                      errorText: _errorMessage,
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isSearching ? null : () => _loadGroupData(_groupController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'CONFERMA E CERCA',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}