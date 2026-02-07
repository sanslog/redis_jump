import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../redis_console_basic/redis_command_parser.dart';
import '../redis_console_basic/redis_connection.dart';
import '../redis_console_basic/redis_formatter.dart';
import '../redis_console_basic/redis_socket_client.dart';
import 'redis_connect_dialog.dart';

//=============面向外部================
class RedisClientPage extends StatelessWidget {
  const RedisClientPage({super.key, this.host, this.port, this.password});
  final String? host;
  final int? port;
  final String? password;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => _RedisConsoleProvider(),
      child: _RedisConsolePage(
        key: key,
        host: host,
        port: port,
        password: password,
      ),
    );
  }
}

//=================内部包装===================
class _RedisConsolePage extends StatefulWidget {
  const _RedisConsolePage({super.key, this.host, this.port, this.password});
  final String? host;
  final int? port;
  final String? password;

  @override
  State<_RedisConsolePage> createState() => _RedisConsolePageState();
}

class _RedisConsolePageState extends State<_RedisConsolePage> {
  final _scroll = ScrollController();
  final _input = TextEditingController();
  final _focus = FocusNode();

  bool _showToBottom = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<_RedisConsoleProvider>();
      try {
        await provider.autoConnect(
          host: widget.host ?? "127.0.0.1",
          port: widget.port ?? 6379,
          password: widget.password ?? "",
        );
      } catch (_) {
        _showConnectDialog();
      }
    });

    _scroll.addListener(_onScroll);

    // 在此处直接拦截 FocusNode 的按键事件
    _focus.onKeyEvent = (node, event) {
      // 只处理按下事件 (KeyDown)，忽略抬起事件
      if (event is! KeyDownEvent) {
        return KeyEventResult.ignored;
      }

      final provider = context.read<_RedisConsoleProvider>();

      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        final h = provider.historyUp();
        if (h != null) {
          _updateInput(h);
        }
        // 返回 handled 告诉 Flutter：我们已经处理了这个按键，不要让 TextField 再处理了
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        final h = provider.historyDown();
        if (h != null) {
          _updateInput(h);
        }
        return KeyEventResult.handled;
      }

      return KeyEventResult.ignored;
    };
  }

  // 提取更新输入框的逻辑
  void _updateInput(String text) {
    _input.text = text;
    // 将光标移动到文本末尾
    _input.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
  }

  void _onScroll() {
    // 优化：只有当状态确实需要改变时才触发 setState
    final atBottom = _scroll.offset >= _scroll.position.maxScrollExtent - 50;
    if (_showToBottom == atBottom) {
      setState(() => _showToBottom = !atBottom);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _showConnectDialog() async {
    final cfg = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RedisConnectDialog(),
    );

    if (cfg != null) {
      if (!mounted) return;
      await context.read<_RedisConsoleProvider>().connect(cfg);
    }
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    // 使用微任务或延时确保在下一帧滚动，避免布局抖动
    Future.microtask(() {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 30, 31, 34),
      body: Consumer<_RedisConsoleProvider>(
        builder: (context, provider, _) {
          final entries = provider.entries;
          final itemCount = entries.length + 1;

          return ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: itemCount,
            // 关键优化：保持较长的缓存区域，防止输入框在滚动时因移出视图而销毁
            cacheExtent: 300,
            itemBuilder: (context, index) {
              if (index == itemCount - 1) {
                return _CommandInput(
                  key: const ValueKey('terminal_input_field'),
                  controller: _input,
                  focusNode: _focus, // 传入外部定义的 FocusNode
                  enabled: provider.connected,
                  prompt: provider.config == null
                      ? "Connecting..."
                      : provider.client.prompt(provider.config!),
                  onSubmit: (text) async {
                    // 1. 先清空输入
                    _input.clear();

                    // 2. 执行逻辑
                    if (text.trim().isNotEmpty) {
                      await provider.execute(text);
                    }

                    // 3. 核心修复：强制在下一帧重新抓回焦点
                    // 因为 ListView 更新子项索引会导致焦点瞬时丢失
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_focus.hasFocus) {
                        _focus.requestFocus();
                      }
                      _scrollToBottom();
                    });
                  },
                );
              }
              return _ConsoleBlock(entry: entries[index]);
            },
          );
        },
      ),
    );
  }
}

//============日志块================
class _ConsoleBlock extends StatelessWidget {
  final ConsoleEntry entry;
  const _ConsoleBlock({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 模拟命令行输入显示
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                ">",
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  entry.command,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 241, 235, 235),
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 命令行输出显示
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: SelectableText(
              entry.result,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
          const Divider(color: Colors.white10),
        ],
      ),
    );
  }
}

//================输入文本框组件====================
class _CommandInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String prompt;
  final ValueChanged<String> onSubmit;

  const _CommandInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.prompt,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          prompt,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode, // 直接将 Node 挂在 TextField 上
            enabled: enabled,
            autofocus: true,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Colors.white,
            ),
            // 关键设置：避免系统在按 Enter 时认为输入已结束而收起键盘
            textInputAction: TextInputAction.send,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: onSubmit,
          ),
        ),
      ],
    );
  }
}

//=================provider====================
class ConsoleEntry {
  final String command;
  final String result;
  ConsoleEntry(this.command, this.result);
}

class _RedisConsoleProvider extends ChangeNotifier {
  final RedisSocketClient client = RedisSocketClient();
  RedisConnectionConfig? config;

  final List<ConsoleEntry> _entries = [];
  final List<String> _history = [];

  /// 光标位置：指向 history 中的索引
  /// history.length 代表“当前是空输入行”
  int _historyCursor = 0;

  List<ConsoleEntry> get entries => List.unmodifiable(_entries);
  bool get connected => client.isConnected;

  ///socket连接基本方法
  Future<void> connect(RedisConnectionConfig cfg) async {
    await client.connect(cfg);
    config = cfg;
    notifyListeners();
  }

  Future<void> autoConnect({
    required String host,
    required int port,
    required String password,
  }) async {
    final cfg = RedisConnectionConfig(
      host: host,
      port: port,
      password: password,
    ); //port 6379
    await connect(cfg);
  }

  ///向redis客户端发送信息
  Future<void> execute(String input) async {
    final cmd = input.trim();
    if (cmd.isEmpty) return;

    // ===== 维护历史 =====
    _history.add(cmd);
    _historyCursor = _history.length; // ★ 回到“空输入行”

    final prompt = client.prompt(config!);
    final parts = RedisCommandParser.parse(cmd);
    try {
      final result = await client.execute(parts);
      _entries.add(ConsoleEntry('$prompt$cmd', RedisFormatter.format(result)));
    } catch (e) {
      _entries.add(
        ConsoleEntry(
          '$prompt$cmd',
          'Connection error,you may have lost the connection.',
        ),
      );
    }
    // ===== 渲染上限 =====
    if (_entries.length > 300) {
      _entries.removeRange(0, _entries.length - 300);
    }

    notifyListeners();
  }

  /// ↑：上一条历史命令
  String? historyUp() {
    if (_history.isEmpty) return null;

    if (_historyCursor > 0) {
      _historyCursor--;
    }
    return _history[_historyCursor];
  }

  /// ↓：下一条历史命令
  /// 到底后回到空输入
  String? historyDown() {
    if (_history.isEmpty) return null;

    if (_historyCursor < _history.length - 1) {
      _historyCursor++;
      return _history[_historyCursor];
    }

    _historyCursor = _history.length;
    return '';
  }
}
