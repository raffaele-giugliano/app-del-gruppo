import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/csv_service.dart';

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

  @override
  void initState() {
    super.initState();
    _checkSavedGroup();
  }

  /// Controlla all'avvio se esiste già un gruppo memorizzato
  Future<void> _checkSavedGroup() async {
    final group = await _storageService.getSavedGroup();
    setState(() {
      _savedGroup = group;
      if (group != null) {
        _groupController.text = group;
      }
      _isLoading = false;
    });
  }

  /// Invia il gruppo al BE per verificare la validità e ottenere l'URL
  Future<void> _submitGroup(String groupName) async {
    if (groupName.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Inserisci il nome del gruppo';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final csvService = CsvService(backendBaseUrl: widget.backendBaseUrl);
      final csvUrl = await csvService.getCsvUrlForGroup(groupName);

      await _storageService.saveGroup(groupName);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gruppo trovato! URL: $csvUrl')),
      );

      setState(() {
        _savedGroup = groupName;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gruppo non trovato o non valido.';
        _isSearching = false;
      });
    }
  }

  /// Cancella il gruppo salvato per avviarne una nuova ricerca
  Future<void> _resetGroup() async {
    await _storageService.clearGroup();
    setState(() {
      _savedGroup = null;
      _groupController.clear();
      _errorMessage = null;
    });
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
              crossAxisAlignment: CrossAxisAlignment.stretch, // <--- Corretto qui (CrossAxisAlignment)
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
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isSearching ? null : () => _submitGroup(_savedGroup!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent[700],
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
                            'ACCEDI AI DATI DEL GRUPPO',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                  ),
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
                      hintText: 'Es: CSRB_2013_SquadraB',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.search),
                      errorText: _errorMessage,
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isSearching ? null : () => _submitGroup(_groupController.text),
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