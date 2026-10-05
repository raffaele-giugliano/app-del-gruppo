import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/page_config.dart';
import 'detail_screen.dart';

class TableViewScreen extends StatefulWidget {
  final PageConfig pageConfig;

  const TableViewScreen({Key? key, required this.pageConfig}) : super(key: key);

  @override
  State<TableViewScreen> createState() => _TableViewScreenState();
}

class _TableViewScreenState extends State<TableViewScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<String> _headers = [];
  List<Map<String, String>> _rows = [];
  int _highlightedIndex = -1;

  final List<GlobalKey> _itemKeys = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.pageConfig.tables.length > 1) {
      setState(() {
        _errorMessage = 'Pagina con più tabelle: funzionalità in fase di sviluppo.';
        _isLoading = false;
      });
      return;
    }

    final table = widget.pageConfig.tables.first;

    if (table.csvUrl.trim().isEmpty) {
      setState(() {
        _errorMessage = 'URL della tabella non valido o mancante.';
        _isLoading = false;
      });
      return;
    }

    try {
      final uri = Uri.parse(table.csvUrl.trim());
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Errore download CSV (HTTP ${response.statusCode})');
      }

      final csvContent = utf8.decode(response.bodyBytes);
      _parseCsvData(csvContent);

      setState(() {
        _isLoading = false;
      });

      // Scroll automatico dopo che l'interfaccia è costruita
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToHighlightedItem();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossibile scaricare o leggere i dati della tabella.';
        _isLoading = false;
      });
    }
  }

  void _parseCsvData(String csvContent) {
    final lines = LineSplitter.split(csvContent)
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.length <= 1) {
      throw Exception('CSV vuoto o senza righe di dati');
    }

    _headers = _parseCsvLine(lines.first).map((e) => e.trim()).toList();

    List<Map<String, String>> parsedRows = [];

    for (int i = 1; i < lines.length; i++) {
      final values = _parseCsvLine(lines[i]);
      final Map<String, String> rowMap = {};

      for (int j = 0; j < _headers.length; j++) {
        rowMap[_headers[j]] = j < values.length ? values[j].trim() : '';
      }
      parsedRows.add(rowMap);
    }

    if (_headers.isNotEmpty && _headers.first.toLowerCase().contains('giorno')) {
      _processDateOrDayOrdering(parsedRows, _headers.first);
    } else {
      _rows = parsedRows;
    }

    _itemKeys.clear();
    for (int i = 0; i < _rows.length; i++) {
      _itemKeys.add(GlobalKey());
    }
  }

  void _processDateOrDayOrdering(List<Map<String, String>> rows, String firstColName) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    List<_RowDateHelper> rowHelpers = [];

    for (var row in rows) {
      final val = row[firstColName] ?? '';
      DateTime? dt = _parseDate(val);

      if (dt == null) {
        dt = _parseWeekdayToNextDate(val, today);
      }

      rowHelpers.add(_RowDateHelper(row: row, parsedDate: dt));
    }

    rowHelpers.sort((a, b) {
      if (a.parsedDate == null && b.parsedDate == null) return 0;
      if (a.parsedDate == null) return 1;
      if (b.parsedDate == null) return -1;
      return a.parsedDate!.compareTo(b.parsedDate!);
    });

    _rows = rowHelpers.map((e) => e.row).toList();

    _highlightedIndex = -1;
    for (int i = 0; i < rowHelpers.length; i++) {
      if (rowHelpers[i].parsedDate != null &&
          !rowHelpers[i].parsedDate!.isBefore(today)) {
        _highlightedIndex = i;
        break;
      }
    }
  }

  DateTime? _parseDate(String val) {
    final parts = val.replaceAll('/', '-').split('-');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  DateTime? _parseWeekdayToNextDate(String val, DateTime today) {
    final clean = val.toLowerCase().trim().replaceAll("'", "ì");
    int? targetWeekday;

    if (clean.contains('lun')) targetWeekday = DateTime.monday;
    else if (clean.contains('mar')) targetWeekday = DateTime.tuesday;
    else if (clean.contains('mer')) targetWeekday = DateTime.wednesday;
    else if (clean.contains('gio')) targetWeekday = DateTime.thursday;
    else if (clean.contains('ven')) targetWeekday = DateTime.friday;
    else if (clean.contains('sab')) targetWeekday = DateTime.saturday;
    else if (clean.contains('dom')) targetWeekday = DateTime.sunday;

    if (targetWeekday != null) {
      int daysAhead = targetWeekday - today.weekday;
      if (daysAhead < 0) daysAhead += 7;
      return today.add(Duration(days: daysAhead));
    }

    return null;
  }

  void _scrollToHighlightedItem() {
    if (_highlightedIndex >= 0 && _highlightedIndex < _itemKeys.length) {
      final context = _itemKeys[_highlightedIndex].currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    final StringBuffer current = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        insideQuotes = !insideQuotes;
      } else if (char == ',' && !insideQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageConfig.pageName),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 64,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ),
      );
    }

    // ListView.builder permette lo scroll completo della lista schede
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12.0),
      itemCount: _rows.length,
      itemBuilder: (context, index) {
        final row = _rows[index];
        final isHighlighted = index == _highlightedIndex;
        final previewEntries = row.entries.take(4).toList();

        return Card(
          key: _itemKeys[index],
          margin: const EdgeInsets.only(bottom: 12.0),
          elevation: isHighlighted ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isHighlighted
                ? const BorderSide(color: Colors.blueAccent, width: 2)
                : BorderSide.none,
          ),
          color: isHighlighted ? const Color(0xFFEFF6FF) : Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(rowData: row),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isHighlighted) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PROSSIMO IMPEGNO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: previewEntries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${entry.key}: ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextSpan(
                                      text: entry.value,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey,
                        size: 28,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RowDateHelper {
  final Map<String, String> row;
  final DateTime? parsedDate;

  _RowDateHelper({required this.row, this.parsedDate});
}