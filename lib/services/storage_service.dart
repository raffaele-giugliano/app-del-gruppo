import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _groupKey = 'selected_group';

  /// Salva il nome del gruppo in locale
  Future<void> saveGroup(String groupName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_groupKey, groupName.trim());
  }

  /// Recupera il nome del gruppo salvato (restituisce null se non presente)
  Future<String?> getSavedGroup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_groupKey);
  }

  /// Rimuove il gruppo salvato per consentire il cambio gruppo
  Future<void> clearGroup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_groupKey);
  }
}