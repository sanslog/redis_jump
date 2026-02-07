import 'resp.dart';

class RedisFormatter {
  static String format(dynamic v) {
    if (v == null) return '(nil)';
    if (v is RedisError) return '(error) ${v.message}';
    if (v is int) return '(integer) $v';
    if (v is String) return '"$v"';

    if (v is List) {
      final b = StringBuffer();
      for (var i = 0; i < v.length; i++) {
        b.writeln('${i + 1}) ${format(v[i])}');
      }
      return b.toString().trimRight();
    }
    return v.toString();
  }
}
