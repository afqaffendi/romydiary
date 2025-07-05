import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'homepage.dart';
import 'profile.dart';
import 'settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final darkMode = prefs.getBool('darkMode') ?? true;
  final fontStyle = prefs.getString('fontStyle') ?? 'Quicksand';
  final fontSize = prefs.getDouble('fontSize') ?? 16.0;
  
  runApp(DreamDiaryApp(
    initialDarkMode: darkMode,
    initialFont: fontStyle,
    initialFontSize: fontSize,
  ));
}

class DreamDiaryApp extends StatefulWidget {
  final bool initialDarkMode;
  final String initialFont;
  final double initialFontSize;

  const DreamDiaryApp({
    Key? key,
    required this.initialDarkMode,
    required this.initialFont,
    required this.initialFontSize,
  }) : super(key: key);

  @override
  State<DreamDiaryApp> createState() => _DreamDiaryAppState();
}

class _DreamDiaryAppState extends State<DreamDiaryApp> {
  late bool _darkMode;
  late String _fontStyle;
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _darkMode = widget.initialDarkMode;
    _fontStyle = widget.initialFont;
    _fontSize = widget.initialFontSize;
  }

  void _updateTheme(bool darkMode) async {
    setState(() => _darkMode = darkMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', darkMode);
  }

  void _updateFont(String font) async {
    setState(() => _fontStyle = font);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontStyle', font);
  }

  void _updateFontSize(double size) async {
    setState(() => _fontSize = size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', size);
  }

  TextTheme _buildTextTheme(TextTheme baseTheme) {
    return GoogleFonts.getTextTheme(
      _fontStyle,
      baseTheme.copyWith(
        bodyLarge: baseTheme.bodyLarge?.copyWith(fontSize: _fontSize),
        bodyMedium: baseTheme.bodyMedium?.copyWith(fontSize: _fontSize),
        titleLarge: baseTheme.titleLarge?.copyWith(fontSize: _fontSize + 4),
        titleMedium: baseTheme.titleMedium?.copyWith(fontSize: _fontSize + 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dream Diary',
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        textTheme: _buildTextTheme(Theme.of(context).textTheme),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          titleTextStyle: GoogleFonts.getFont(
            _fontStyle,
            fontSize: _fontSize + 6,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) => states.contains(MaterialState.selected)
                ? Colors.deepPurple
                : Colors.grey,
          ),
          trackColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) => states.contains(MaterialState.selected)
                ? Colors.deepPurple.withOpacity(0.5)
                : Colors.grey.withOpacity(0.5),
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: _buildTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: const Color(0xFF0F0B21),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          titleTextStyle: GoogleFonts.getFont(
            _fontStyle,
            fontSize: _fontSize + 6,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) => states.contains(MaterialState.selected)
                ? Colors.deepPurple
                : Colors.grey,
          ),
          trackColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) => states.contains(MaterialState.selected)
                ? Colors.deepPurple.withOpacity(0.5)
                : Colors.grey.withOpacity(0.5),
          ),
        ),
      ),
      home: const HomePage(),
      routes: {
        '/profile': (context) => const ProfilePage(),
        '/settings': (context) => SettingsPage(
              onThemeChanged: _updateTheme,
              onFontChanged: _updateFont,
              onFontSizeChanged: _updateFontSize,
            ),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}