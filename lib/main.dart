import 'package:flutter/material.dart';
import 'package:DOOF/auth/auth_gate.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:DOOF/secrets.dart';

void main() async {
  // These settings are important for the Open Food Facts API
  OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'FILO');
  OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
    OpenFoodFactsLanguage.ENGLISH,
  ];
  runApp(const MyApp());

  await Supabase.initialize(url: supabaseURL, anonKey: supabaseAnon);
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
      home: const AuthGate(),
    );
  }
}
