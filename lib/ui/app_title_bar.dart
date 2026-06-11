import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:redis_jump/model/basic_info_model.dart';
import 'package:window_manager/window_manager.dart';

class AppTitleBar extends StatelessWidget {
  const AppTitleBar({super.key, this.onLinkTap});
  final VoidCallback? onLinkTap;

  @override
  Widget build(BuildContext context) {
    bool isMaximized = context.select<BasicInfoModel, bool>(
      (model) => model.windowIsMaxed,
    );
    return Container(
      height: 30,
      color: const Color.fromARGB(255, 60, 60, 60),
      child: Row(
        children: [
          // 应用图标 + 标题 + 链接按钮（不可拖拽）
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.apps,
                  size: 16,
                  color: Color.fromARGB(255, 250, 250, 250),
                ),
                const SizedBox(width: 8),
                const Text(
                  'RedisJump',
                  style: TextStyle(
                    color: Color.fromARGB(255, 239, 239, 239),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 15),
                _LinkButton(onTap: onLinkTap),
              ],
            ),
          ),

          // 拖拽区域
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => windowManager.startDragging(),
              child: Container(height: 30),
            ),
          ),

          // 窗口控制按钮
          Row(
            children: [
              // 最小化按钮
              _buildWindowButton(
                icon: Icons.arrow_downward,
                onPressed: () => windowManager.minimize(),
              ),

              // 最大化/还原按钮
              _buildWindowButton(
                icon: isMaximized ? Icons.filter_none : Icons.crop_square,
                onPressed: () => _toggleMaximize(context),
              ),

              // 关闭按钮
              _buildWindowButton(
                icon: Icons.close,
                onPressed: () => windowManager.close(),
                hoverColor: const Color(0xFFE81123),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildWindowButton({
  required IconData icon,
  required VoidCallback onPressed,
  Color? hoverColor,
}) {
  return SizedBox(
    width: 46,
    height: 30,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        hoverColor: hoverColor ?? Color.fromARGB(255, 117, 113, 113),
        child: Icon(
          icon,
          size: icon == Icons.minimize ? 18 : 16,
          color: Color.fromARGB(255, 213, 209, 209),
        ),
      ),
    ),
  );
}
Future<void> _toggleMaximize(BuildContext context) async {
  final model = context.read<BasicInfoModel>();
  if (await windowManager.isMaximized()) {
    await windowManager.unmaximize();
    model.setIsMaxed(false);
  } else {
    await windowManager.maximize();
    model.setIsMaxed(true);
  }
}

/// 链接按钮（点击弹出 Redis 连接对话框）
class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: const Color.fromARGB(255, 117, 113, 113),
          child: const Icon(
            Icons.link,
            size: 14,
            color: Color.fromARGB(255, 213, 209, 209),
          ),
        ),
      ),
    );
  }
}
