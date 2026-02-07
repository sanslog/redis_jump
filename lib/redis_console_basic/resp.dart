import 'dart:convert';

class RedisError {
  final String message;
  RedisError(this.message);
}

class _NeedMoreData implements Exception {}

class RESPStreamDecoder {
  final List<int> _buffer = [];
  int _offset = 0;

  Iterable<dynamic> feed(List<int> chunk) sync* {
    _buffer.addAll(chunk);

    while (true) {
      try {
        final value = _parse();
        if (value == null) break;
        yield value;
      } on _NeedMoreData {
        break;
      }
    }

    if (_offset > 0) {
      _buffer.removeRange(0, _offset);
      _offset = 0;
    }
  }

  dynamic _parse() {
    if (_offset >= _buffer.length) return null;

    final prefix = String.fromCharCode(_buffer[_offset++]);
    switch (prefix) {
      case '+':
        return _readLine();
      case '-':
        return RedisError(_readLine());
      case ':':
        return int.parse(_readLine());
      case '\$':
        return _readBulk();
      case '*':
        return _readArray();
      default:
        throw Exception('Invalid RESP prefix');
    }
  }

  String _readLine() {
    final start = _offset;
    while (true) {
      if (_offset + 1 >= _buffer.length) throw _NeedMoreData();
      if (_buffer[_offset] == 13 && _buffer[_offset + 1] == 10) break;
      _offset++;
    }
    final line = utf8.decode(_buffer.sublist(start, _offset));
    _offset += 2;
    return line;
  }

  dynamic _readBulk() {
    final len = int.parse(_readLine());
    if (len == -1) return null;
    if (_offset + len + 2 > _buffer.length) throw _NeedMoreData();
    final value = utf8.decode(_buffer.sublist(_offset, _offset + len));
    _offset += len + 2;
    return value;
  }

  dynamic _readArray() {
    final count = int.parse(_readLine());
    if (count == -1) return null;
    final list = <dynamic>[];
    for (var i = 0; i < count; i++) {
      list.add(_parse() ?? (throw _NeedMoreData()));
    }
    return list;
  }
}
