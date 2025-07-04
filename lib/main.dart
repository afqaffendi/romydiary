import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DreamDiaryApp());
}

class DreamDiaryApp extends StatelessWidget {
  const DreamDiaryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dream Diary',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        textTheme: GoogleFonts.quicksandTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: GoogleFonts.quicksandTextTheme(
          Theme.of(context).textTheme,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0B21),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}