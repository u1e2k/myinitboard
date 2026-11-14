import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'features/weather/views/weather_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyInitBoardApp());
}

class MyInitBoardApp extends StatelessWidget {
  const MyInitBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'myinitboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShellScreen(),
    );
  }
}

/// Base shell screen designed for future feature expansion (e.g. tasks, news, calendar widgets).
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  // Current active dashboard feature index (default: 0 for Weather)
  final int _currentFeatureIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Currently only weather feature is implemented, but this shell is easily extensible
    switch (_currentFeatureIndex) {
      case 0:
      default:
        return const WeatherDashboardScreen();
    }
  }
}
