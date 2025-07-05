import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui'; // For ImageFilter

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double border;

  const GlassContainer({
    Key? key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 10,
    this.border = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          width: border,
          color: Colors.white.withOpacity(0.2),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: child,
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final Function(String) onFontChanged;
  final Function(double) onFontSizeChanged;

  const SettingsPage({
    Key? key,
    required this.onThemeChanged,
    required this.onFontChanged,
    required this.onFontSizeChanged,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = true;
  bool _notificationsEnabled = true;
  String _fontStyle = 'Quicksand';
  double _fontSize = 16.0;

  final List<String> _availableFonts = [
    'Quicksand',
    'Poppins',
    'Montserrat',
    'Nunito',
    'Comfortaa'
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? true;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _fontStyle = prefs.getString('fontStyle') ?? 'Quicksand';
      _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setString('fontStyle', _fontStyle);
    await prefs.setDouble('fontSize', _fontSize);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B21),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.getFont(
            _fontStyle,
            fontSize: _fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GlassContainer(
              blur: 10,
              child: Column(
                children: [
                  _buildSettingItem(
                    icon: Icons.dark_mode,
                    title: 'Dark Mode',
                    trailing: Switch(
                      value: _darkMode,
                      onChanged: (value) {
                        setState(() => _darkMode = value);
                        widget.onThemeChanged(value);
                        _saveSettings();
                      },
                      activeColor: Colors.deepPurple,
                    ),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.notifications,
                    title: 'Enable Notifications',
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                        _saveSettings();
                      },
                      activeColor: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GlassContainer(
              blur: 10,
              child: Column(
                children: [
                  _buildSettingItem(
                    icon: Icons.font_download,
                    title: 'Font Style',
                    trailing: DropdownButton<String>(
                      value: _fontStyle,
                      dropdownColor: const Color(0xFF1A1A2E),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _fontSize,
                        fontFamily: _fontStyle,
                      ),
                      items: _availableFonts
                          .map((font) => DropdownMenuItem(
                                value: font,
                                child: Text(
                                  font,
                                  style: GoogleFonts.getFont(font),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _fontStyle = value);
                          widget.onFontChanged(value);
                          _saveSettings();
                        }
                      },
                    ),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.format_size,
                    title: 'Font Size',
                    trailing: Text(
                      _fontSize.toStringAsFixed(1),
                      style: GoogleFonts.getFont(
                        _fontStyle,
                        fontSize: _fontSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Slider(
                    value: _fontSize,
                    min: 14.0,
                    max: 22.0,
                    divisions: 8,
                    activeColor: Colors.deepPurple,
                    inactiveColor: Colors.deepPurple.withOpacity(0.3),
                    onChanged: (value) {
                      setState(() => _fontSize = value);
                      widget.onFontSizeChanged(value);
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                ),
              ),
              child: Text(
                'Save Settings',
                style: GoogleFonts.getFont(
                  _fontStyle,
                  fontSize: _fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.getFont(
                _fontStyle,
                fontSize: _fontSize,
                color: Colors.white,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.white.withOpacity(0.1),
      indent: 16,
      endIndent: 16,
    );
  }
}