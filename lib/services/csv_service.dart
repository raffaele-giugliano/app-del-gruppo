import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import '../models/page_config.dart';

class CsvService {
  final String backendBaseUrl;

  CsvService({required this.backendBaseUrl});

  /// 1. Recupera l'URL dell'indice dal Worker Backend
  Future<String> getCsvUrlForGroup(String groupName) async {
    final response = await http.get(
      Uri.parse('$backendBaseUrl?group=${Uri.encodeComponent(groupName)}'),
    );

    if (response.statusCode == 200) {
      final url = response.body.trim();
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      }
      throw Exception('URL non valido dal backend: $url');
    } else {
      throw Exception('Errore Backend: ${response.statusCode}');
    }
  }

  /// 2. Scarica e analizza il CSV di indice del gruppo
  Future<List<PageConfig>> fetchGroupIndex(String indexCsvUrl) async {
    final response = await http.get(Uri.parse(indexCsvUrl));

    if (response.statusCode != 200) {
      throw Exception('Impossibile scaricare l\'indice CSV del gruppo');
    }

    // Parsing del CSV
    final String csvRaw = response.body;
    final List<List<dynamic>> rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(csvRaw);

    if (rows.length <= 1) {
      return []; // Nessun dato o solo intestazione
    }

    // Mappa temporanea per raggruppare per Nome Pagina (Colonna 0)
    final Map<String, List<TableInfo>> pageMap = {};

    // Salta la prima riga (intestazione)
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length >= 3) {
        final String pageName = row[0].toString().trim();
        final String tableName = row[1].toString().trim();
        final String tableUrl = row[2].toString().trim();

        if (pageName.isNotEmpty && tableUrl.isNotEmpty) {
          pageMap.putIfAbsent(pageName, () => []);
          pageMap[pageName]!.add(
            TableInfo(tableName: tableName, csvUrl: tableUrl),
          );
        }
      }
    }

    // Converti la mappa in lista di PageConfig
    return pageMap.entries
        .map((entry) => PageConfig(pageName: entry.key, tables: entry.value))
        .toList();
  }
}