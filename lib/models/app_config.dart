class AppConfig {
  final String groupName;
  final String backendBaseUrl;

  AppConfig({
    required this.groupName,
    this.backendBaseUrl = 'https://app-del-gruppo.raffaele-giugliano.workers.dev',
  });

  bool get hasGroup => groupName.isNotEmpty;
}