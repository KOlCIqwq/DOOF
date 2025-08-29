import 'package:flutter/material.dart';
import 'package:food/auth/auth_gate.dart';
import 'package:food/pages/main_page.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // These settings are important for the Open Food Facts API
  OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'FILO');
  OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
    OpenFoodFactsLanguage.ENGLISH,
  ];
  runApp(const MyApp());

  await Supabase.initialize(
    url: 'https://ddzmfhkcecdpvefswled.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkem1maGtjZWNkcHZlZnN3bGVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY0NTE0MTMsImV4cCI6MjA3MjAyNzQxM30.TNn79QmTpkYdrYgf7X7LgiWDUKGSFOxW16JRKMG0nuw',
  );
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
