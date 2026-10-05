class TableInfo {
  final String tableName;
  final String csvUrl;

  TableInfo({
    required this.tableName,
    required this.csvUrl,
  });
}

class PageConfig {
  final String pageName;
  final List<TableInfo> tables;

  PageConfig({
    required this.pageName,
    required this.tables,
  });
}