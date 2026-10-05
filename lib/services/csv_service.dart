import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/page_config.dart';

class CsvService {
  final String backendBaseUrl;

  CsvService({required this.backendBaseUrl});

  /// 1. Recupera l'URL dal Backend e lo pulisce da caratteri invisibili
  Future<String> getCsvUrlForGroup(String groupName) async {
    final cleanGroup = groupName.trim();
    final url = '$backendBaseUrl?group=${Uri.encodeComponent(cleanGroup)}';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Errore Backend (HTTP ${response.statusCode})');
    }

    // Pulizia rigorosa da spazi, virgolette e a capo
    String rawUrl = response.body.trim();
    rawUrl = rawUrl.replaceAll('\r', '').replaceAll('\n', '');
    if (rawUrl.startsWith('"') && rawUrl.endsWith('"')) {
      rawUrl = rawUrl.substring(1, rawUrl.length - 1);
    }

    if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
      throw Exception('URL dal backend non valido: "$rawUrl"');
    }

    return rawUrl;
  }

  /// 2. Scarica il file CSV usando esattamente lo stesso metodo delle app precedenti
  Future<List<PageConfig>> fetchGroupIndex(String indexCsvUrl) async {
    // Usiamo Uri.parse direttamente sulla stringa pulita, esattamente come per i link hardcoded
    final uri = Uri.parse(indexCsvUrl.trim());

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Errore download CSV (HTTP ${response.statusCode})');
    }

    // Decodifica UTF-8
    final csvContent = utf8.decode(response.bodyBytes);
    return parseIndexCsv(csvContent);
  }

  /// 3. Parsing delle righe CSV
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
      throw Exception('Nessun dato trovato nel CSV.');
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