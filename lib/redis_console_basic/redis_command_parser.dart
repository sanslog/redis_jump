class RedisCommandParser {
  static List<String> parse(String input) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (var i = 0; i < input.length; i++) {
      final c = input[i];

      if (c == '"') {
        inQuotes = !inQuotes;
        continue;
      }

      if (c == ' ' && !inQuotes) {
        if (buffer.isNotEmpty) {
          result.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(c);
      }
    }

    if (buffer.isNotEmpty) result.add(buffer.toString());
    return result;
  }
}
