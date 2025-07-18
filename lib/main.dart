import 'package:flutter/material.dart';
import 'package:food/pages/main_page.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

void main() {
  // These settings are important for the Open Food Facts API
  OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'FILO');
  OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
    OpenFoodFactsLanguage.ENGLISH,
  ];
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        // Optional: Add some cohesive colors
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}
