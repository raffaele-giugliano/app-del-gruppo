import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import '../models/page_config.dart';

class CsvService {
  final String backendBaseUrl;

  CsvService({required this.backendBaseUrl});

  Future<String> getCsvUrlForGroup(String groupName) async {
    final response = await http.get(
      Uri.parse('$backendBaseUrl?group=${Uri.encodeComponent(groupName)}'),
    );

    if (response.statusCode == 200) {
      final url = response.body.trim();
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      }
      throw Exception('URL non valido restituito dal backend: "$url"');
    } else {
      throw Exception('Errore Worker Backend (${response.statusCode}): ${response.body}');
    }
  }

  Future<List<PageConfig>> fetchGroupIndex(String indexCsvUrl) async {
    final response = await http.get(Uri.parse(indexCsvUrl));

    if (response.statusCode != 200) {
      throw Exception('Errore download CSV indice (HTTP ${response.statusCode})');
    }

    // Normalizza i fine riga (\r\n -> \n)
    final String csvRaw = response.body.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final List<List<dynamic>> rows = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(csvRaw);

    if (rows.length <= 1) {
      throw Exception('Il file CSV scaricato è vuoto o contiene solo l\'intestazione.');
    }

    final Map<String, List<TableInfo>> pageMap = {};

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

    if (pageMap.isEmpty) {
      throw Exception('Nessuna riga valida con 3 colonne trovata nel CSV.');
    }

    return pageMap.entries
        .map((entry) => PageConfig(pageName: entry.key, tables: entry.value))
        .toList();
  }
}