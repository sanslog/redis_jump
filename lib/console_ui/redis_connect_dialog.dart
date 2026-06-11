import 'package:flutter/material.dart';

import '../redis_console_basic/redis_connection.dart';

class RedisConnectDialog extends StatefulWidget {
  final Future<bool> Function(RedisConnectionConfig)? onConnect;
  final VoidCallback? onCancel;

  const RedisConnectDialog({super.key, this.onConnect, this.onCancel});

  @override
  State<RedisConnectDialog> createState() => _RedisConnectDialogState();
}

class _RedisConnectDialogState extends State<RedisConnectDialog> {
  final host = TextEditingController();
  final port = TextEditingController();
  final password = TextEditingController();

  bool _connecting = false;
  String? _errorMessage;

  @override
  void dispose() {
    host.dispose();
    port.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    // 端口校验
    final portText = port.text.trim();
    if (portText.isEmpty) {
      setState(() => _errorMessage = '请输入端口号');
      return;
    }
    final portNum = int.tryParse(portText);
    if (portNum == null) {
      setState(() => _errorMessage = '端口号格式错误');
      return;
    }

    setState(() {
      _connecting = true;
      _errorMessage = null;
    });

    try {
      final cfg = RedisConnectionConfig(
        host: host.text,
        port: portNum,
        password: password.text.isEmpty ? null : password.text,
      );
      final ok = await widget.onConnect?.call(cfg) ?? false;
      if (!mounted) return;
      if (ok) {
        widget.onCancel?.call();
      } else {
        setState(() {
          _connecting = false;
          _errorMessage = '连接失败，请检查网络环境和账户密码';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _connecting = false;
          _errorMessage = '连接失败，请检查网络环境和账户密码';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 30, 31, 34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      title: const Text(
        'Connect to Redis',
        style: TextStyle(
          color: Color.fromARGB(255, 241, 235, 235),
          fontFamily: 'monospace',
          fontSize: 16,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
            ),
            controller: host,
            decoration: const InputDecoration(
              labelText: 'Host',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.greenAccent),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
            ),
            controller: port,
            decoration: const InputDecoration(
              labelText: 'Port',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.greenAccent),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
            ),
            controller: password,
            decoration: const InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.greenAccent),
              ),
            ),
            obscureText: true,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          onPressed: _connecting ? null : () => widget.onCancel?.call(),
          icon: const Icon(
            Icons.close_outlined,
            color: Colors.white70,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _connecting ? null : _onConfirm,
          icon: _connecting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.greenAccent,
                  ),
                )
              : const Icon(
                  Icons.check_outlined,
                  color: Colors.greenAccent,
                ),
        ),
      ],
    );
  }
}
