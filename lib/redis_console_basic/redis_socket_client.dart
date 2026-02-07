import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:redis_jump/redis_console_basic/redis_connection.dart';
import 'package:redis_jump/redis_console_basic/resp.dart';

class RedisSocketClient {
  Socket? _socket;
  final _decoder = RESPStreamDecoder();
  final Queue<Completer<dynamic>> _pending = Queue();

  bool get isConnected => _socket != null;

  String prompt(RedisConnectionConfig cfg) => '${cfg.host}:${cfg.port}> ';

  Future<void> connect(RedisConnectionConfig config) async {
    _socket = await Socket.connect(config.host, config.port);
    _socket!.listen(_onData, onDone: disconnect);

    if (config.password != null && config.password!.isNotEmpty) {
      final auth = await execute(['AUTH', config.password!]);
      if (auth is RedisError) {
        disconnect();
        throw Exception(auth.message);
      }
    }
  }

  Future<dynamic> execute(List<String> command) {
    final completer = Completer<dynamic>();
    _pending.add(completer);
    _socket!.add(_encode(command));
    return completer.future;
  }

  void _onData(List<int> data) {
    for (final resp in _decoder.feed(data)) {
      if (_pending.isNotEmpty) {
        _pending.removeFirst().complete(resp);
      }
    }
  }

  void disconnect() {
    _socket?.destroy();
    _socket = null;
    while (_pending.isNotEmpty) {
      _pending.removeFirst().completeError(RedisError('Connection closed'));
    }
  }

  List<int> _encode(List<String> parts) {
    final b = StringBuffer('*${parts.length}\r\n');
    for (final p in parts) {
      final bytes = utf8.encode(p);
      b.write('\$${bytes.length}\r\n$p\r\n');
    }
    return utf8.encode(b.toString());
  }
}
