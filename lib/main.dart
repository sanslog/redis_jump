import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:redis_jump/ui/app_title_bar.dart';
import 'package:window_manager/window_manager.dart';

import 'console_ui/redis_console_page.dart';
import 'model/basic_info_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1000, 700),
    minimumSize: Size(850, 600),
    center: true,
    titleBarStyle: TitleBarStyle.hidden, // 隐藏原生标题栏
    backgroundColor: Colors.transparent,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BasicInfoModel()),
        // ChangeNotifierProvider(create: (context) => RedisConsoleProvider()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MainPage(),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppTitleBar(),
          // RedisClient内容区域
          Expanded(child: RedisClientPage()),
        ],
      ),
    );
  }
}
