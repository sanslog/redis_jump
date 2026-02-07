import 'package:flutter/material.dart';

import '../redis_console_basic/redis_connection.dart';

class RedisConnectDialog extends StatefulWidget {
  const RedisConnectDialog({super.key});

  @override
  State<RedisConnectDialog> createState() => _RedisConnectDialogState();
}

class _RedisConnectDialogState extends State<RedisConnectDialog> {
  final host = TextEditingController();
  final port = TextEditingController();
  final password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color.fromARGB(255, 43, 45, 48),
      title: const Text(
        'Connect to Redis',
        style: TextStyle(color: Color.fromARGB(255, 207, 207, 207)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            style: TextStyle(color: Color.fromARGB(255, 207, 207, 207)),
            controller: host,
            decoration: const InputDecoration(
              labelText: 'Host',
              labelStyle: TextStyle(color: Color.fromARGB(255, 207, 207, 207)),
            ),
          ),
          TextField(
            style: TextStyle(color: Color.fromARGB(255, 207, 207, 207)),
            controller: port,
            decoration: const InputDecoration(
              labelText: 'Port',
              labelStyle: TextStyle(color: Color.fromARGB(255, 207, 207, 207)),
            ),
          ),
          TextField(
            style: TextStyle(color: Color.fromARGB(255, 207, 207, 207)),
            controller: password,
            decoration: const InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: Color.fromARGB(255, 207, 207, 207)),
            ),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.close_outlined,
            color: Color.fromARGB(255, 207, 207, 207),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            Navigator.pop(
              context,
              RedisConnectionConfig(
                host: host.text,
                port: int.parse(port.text),
                password: password.text.isEmpty ? null : password.text,
              ),
            );
          },
          icon: Icon(
            Icons.check_outlined,
            color: Color.fromARGB(255, 207, 207, 207),
          ),
        ),
      ],
    );
  }
}
