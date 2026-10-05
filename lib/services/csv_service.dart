import 'dart5/convert';
import 'package:http/http.dart' as http;
import '../models/page_config.dart';

class CsvService {
  final String backendBaseUrl;

  CsvService({required this.backendBaseUrl});

  /// Chiede al Backend/Worker l'URL dell'indice CSV per un determinato gruppo
  Future<String> getCsvUrlForGroup(String groupName) async {
    final cleanGroup = groupName.trim();
    final uri = Uri.parse('$backendBaseUrl?group=$cleanGroup');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Gruppo non trovato o errore backend (${response.statusCode})');
    }

    // Pulizia della stringa restituita dal backend
    final rawUrl = response.body.trim().replaceAll('\r', '').replaceAll('\n', '');

    final parsedUri = Uri.tryParse(rawUrl);
    if (parsedUri == null || !parsedUri.hasAbsolutePath) {
      throw Exception('L\'URL restituito dal backend non è valido: "$rawUrl"');
    }

    return rawUrl;
  }

  /// Scarica e analizza il CSV indice (Pagina, Tabella, URL)
  Future<List<PageConfig>> fetchGroupIndex(String indexCsvUrl) async {
    final cleanUrl = indexCsvUrl.trim().replaceAll('\r', '').replaceAll('\n', '');
    final uri = Uri.tryParse(cleanUrl);

    if (uri == null || !uri.hasAbsolutePath) {
      throw Exception('URL dell\'indice CSV non valido: "$cleanUrl"');
    }

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Impossibile scaricare l\'indice CSV (${response.statusCode})');
    }

    final csvContent = utf8.decode(response.bodyBytes);
    return parseIndexCsv(csvContent);
  }

  /// Converte il testo CSV dell'indice nelle strutture PageConfig e TableInfo
  List<PageConfig> parseIndexCsv(String csvContent) {
    final lines = LineSplitter.split(csvContent)
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      throw Exception('Il file CSV dell\'indice è vuoto.');
    }

    // Mappa per raggruppare le tabelle per pagina
    final Map<String, List<TableInfo>> pageMap = {};

    // Salta l'intestazione se presente (Pagina,Tabella,URL)
    final startIndex = lines.first.toLowerCase().contains('pagina') ? 1 : 0;

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i];
      final columns = _parseCsvLine(line);

      if (columns.length >= 3) {
        final pageName = columns[0].trim();
        final tableName = columns[1].trim();
        final tableUrl = columns[2].trim().replaceAll('\r', '').replaceAll('\n', '');

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
      throw Exception('Nessuna pagina valida trovata nel CSV dell\'indice.');
    }

    return pageMap.entries
        .map((entry) => PageConfig(
              pageName: entry.key,
              tables: entry.value,
            ))
        .toList();
  }

  /// Helper per la divisione corretta delle righe CSV gestendo le virgolette
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