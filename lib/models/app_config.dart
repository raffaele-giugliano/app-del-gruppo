class AppConfig {
  final String groupName;
  final String backendBaseUrl;

  AppConfig({
    required this.groupName,
    this.backendBaseUrl = 'https://mio-worker.tuousername.workers.dev',
  });

  bool get hasGroup => groupName.isNotEmpty;
}