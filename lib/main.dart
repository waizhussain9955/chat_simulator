import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/navigation_shell.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create provider and initialize storage
  final appProvider = AppProvider();
  await appProvider.init();

  runApp(
    ChangeNotifierProvider<AppProvider>.value(
      value: appProvider,
      child: const ChatSimulatorApp(),
    ),
  );
}

class ChatSimulatorApp extends StatelessWidget {
  const ChatSimulatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Simulator Pro',
      debugShowCheckedModeBanner: false,
      theme: DarkEmeraldTheme.themeData,
      home: const NavigationShell(),
    );
  }
}
