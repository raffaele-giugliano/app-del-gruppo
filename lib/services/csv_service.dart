import 'package:http/http.dart' as http;

class CsvService {
  final String backendUrl;

  CsvService({required this.backendUrl});

  Future<String> fetchGuideSheet(String groupName) async {
    if (groupName.isEmpty) {
      throw Exception('Nessun gruppo specificato.');
    }

    final Uri url = Uri.parse('$backendUrl?group=$groupName');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return response.body;
    } else if (response.statusCode == 400) {
      throw Exception('Gruppo "$groupName" non trovato o non autorizzato.');
    } else {
      throw Exception('Errore del server: ${response.statusCode}');
    }
  }
}