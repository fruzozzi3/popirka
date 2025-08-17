import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'features/savings/viewmodels/savings_view_model.dart';
import 'features/savings/data/repository/savings_repository.dart';
import 'features/savings/ui/screens/home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SavingsViewModel(SavingsRepository())..init(),
        ),
      ],
      child: MaterialApp(
        title: 'Моя Копилка',
        theme: AppTheme.light(),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
