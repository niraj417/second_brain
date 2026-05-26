import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'services/co_pilot_service.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => CoPilotService(),
      child: const SecondBrainApp(),
    ),
  );
}

class SecondBrainApp extends StatelessWidget {
  const SecondBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Second Brain TWS Assistant',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Cyberpunk aesthetic dark mode
      darkTheme: AppTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}
