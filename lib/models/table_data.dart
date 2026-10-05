class TableData {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;

  TableData({
    required this.title,
    required this.headers,
    required this.rows,
  });
}