import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Устанавливаем ориентацию только портретную
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Error in main: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Ошибка запуска: $e'),
          ),
        ),
      ),
    );
  }
}
