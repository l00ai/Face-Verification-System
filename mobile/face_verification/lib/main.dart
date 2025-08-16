import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'verification_screen.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (context) => AppState(),
    child: const MyApp(),
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Verify',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const VerificationScreen(),
    );
  }
}