import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';

class CsvService {
  final String backendBaseUrl;

  CsvService({required this.backendBaseUrl});

  /// 1. Chiama il Worker su Cloudflare per ottenere l'URL del CSV associato al gruppo
  Future<String> getCsvUrlForGroup(String groupName) async {
    final Uri requestUri = Uri.parse('$backendBaseUrl?group=$groupName');

    final response = await http.get(requestUri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('csvUrl')) {
        return data['csvUrl'] as String;
      } else {
        throw Exception('Risposta del server non valida: campo csvUrl mancante');
      }
    } else {
      throw Exception('Gruppo non trovato o errore server (Codice ${response.statusCode})');
    }
  }

  /// 2. Scarica il file CSV da Google Sheets tramite l'URL ottenuto e lo converte in matrice di dati
  Future<List<List<dynamic>>> fetchAndParseCsv(String csvUrl) async {
    final response = await http.get(Uri.parse(csvUrl));

    if (response.statusCode == 200) {
      final String csvText = response.body;
      final List<List<dynamic>> fields = const CsvToListConverter().convert(csvText);
      return fields;
    } else {
      throw Exception('Impossibile scaricare il file CSV da Google Sheets');
    }
  }
}