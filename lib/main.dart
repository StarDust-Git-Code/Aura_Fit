import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/ble_provider.dart';
import 'screens/scan_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleProvider()),
      ],
      child: MaterialApp(
        title: 'Aura Fit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const ScanScreen(),
      ),
    );
  }
}
