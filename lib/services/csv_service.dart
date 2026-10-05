import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/page_config.dart';

class CsvService {
  final String backendBaseUrl;

  CsvService({required this.backendBaseUrl});

  /// 1. Recupera la risposta JSON dal Backend ed estrae la chiave 'csvUrl'
  Future<String> getCsvUrlForGroup(String groupName) async {
    final cleanGroup = groupName.trim();
    final url = '$backendBaseUrl?group=${Uri.encodeComponent(cleanGroup)}';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Errore Backend (HTTP ${response.statusCode})');
    }

    // Decodifica il JSON restituito dal BE
    final Map<String, dynamic> data = jsonDecode(response.body);

    if (!data.containsKey('csvUrl') || data['csvUrl'] == null) {
      throw Exception('Il backend non ha restituito la chiave "csvUrl"');
    }

    final String csvUrl = data['csvUrl'].toString().trim();

    if (!csvUrl.startsWith('http://') && !csvUrl.startsWith('https://')) {
      throw Exception('L\'URL contenuto in csvUrl non è valido: "$csvUrl"');
    }

    return csvUrl;
  }

  /// 2. Scarica il file CSV dall'URL ottenuto dal BE
  Future<List<PageConfig>> fetchGroupIndex(String indexCsvUrl) async {
    final uri = Uri.parse(indexCsvUrl.trim());

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Impossibile scaricare il file CSV (HTTP ${response.statusCode})');
    }

    final csvContent = utf8.decode(response.bodyBytes);
    return parseIndexCsv(csvContent);
  }

  /// 3. Parsing del contenuto CSV dell'indice
  List<PageConfig> parseIndexCsv(String csvContent) {
    final lines = LineSplitter.split(csvContent)
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      throw Exception('Il file CSV scaricato è vuoto.');
    }

    final Map<String, List<TableInfo>> pageMap = {};

    // Salta l'intestazione se la prima riga contiene "pagina"
    final startIndex = lines.first.toLowerCase().contains('pagina') ? 1 : 0;

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i];
      final columns = _parseCsvLine(line);

      if (columns.length >= 3) {
        final pageName = columns[0].trim();
        final tableName = columns[1].trim();
        final tableUrl = columns[2].trim();

        if (pageName.isNotEmpty && tableName.isNotEmpty && tableUrl.isNotEmpty) {
          final tableInfo = TableInfo(
            tableName: tableName,
            csvUrl: tableUrl,
          );

          pageMap.putIfAbsent(pageName, () => []).add(tableInfo);
        }
      }
    }

    if (pageMap.isEmpty) {
      throw Exception('Nessuna pagina/tabella valida trovata nel CSV.');
    }

    return pageMap.entries
        .map((entry) => PageConfig(
              pageName: entry.key,
              tables: entry.value,
            ))
        .toList();
  }

  /// Separazione colonne gestendo eventuali virgolette
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
}