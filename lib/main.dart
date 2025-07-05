import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'homepage.dart';
import 'profile.dart';
import 'settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const DreamDiaryApp());
}

class DreamDiaryApp extends StatefulWidget {
  const DreamDiaryApp({Key? key}) : super(key: key);

  @override
  State<DreamDiaryApp> createState() => _DreamDiaryAppState();
}

class _DreamDiaryAppState extends State<DreamDiaryApp> {
  late Future<bool> _initFuture;
  late bool _darkMode;
  late String _fontStyle;
  late double _fontSize;
  bool _isLoggedIn = false;
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
  }

  Future<bool> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? true;
      _fontStyle = prefs.getString('fontStyle') ?? 'Quicksand';
      _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    });
    
    // Check login status
    final loggedIn = await _auth.isLoggedIn();
    setState(() => _isLoggedIn = loggedIn);
    return true;
  }

  void _updateTheme(bool darkMode) async {
    setState(() => _darkMode = darkMode);
    (await SharedPreferences.getInstance()).setBool('darkMode', darkMode);
  }

  void _updateFont(String font) async {
    setState(() => _fontStyle = font);
    (await SharedPreferences.getInstance()).setString('fontStyle', font);
  }

  void _updateFontSize(double size) async {
    setState(() => _fontSize = size);
    (await SharedPreferences.getInstance()).setDouble('fontSize', size);
  }

  Future<void> _logout() async {
    await _auth.logout();
    setState(() => _isLoggedIn = false);
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
    return FutureBuilder<bool>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: _darkMode ? const Color(0xFF0F0B21) : Colors.white,
              body: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return MaterialApp(
          title: 'Dream Diary',
          debugShowCheckedModeBanner: false,
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
          home: _isLoggedIn ? const HomePage() : LoginScreen(
            onLoginSuccess: () => setState(() => _isLoggedIn = true),
          ),
          routes: {
            '/profile': (context) => const ProfilePage(),
            '/settings': (context) => SettingsPage(
                  onThemeChanged: _updateTheme,
                  onFontChanged: _updateFont,
                  onFontSizeChanged: _updateFontSize,
                ),
          },
        );
      },
    );
  }
}