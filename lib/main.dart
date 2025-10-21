import 'package:flutter/material.dart';
import 'package:teste/screens/contact_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda de Contatos',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFFFFF8F0),
        fontFamily: 'Roboto',
      ),
      home: ContactListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}