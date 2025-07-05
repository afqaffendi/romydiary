import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late double _fontSize;
  late String _selectedFont;

  final List<String> _fontOptions = [
    'Quicksand',
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Poppins',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('fontSize') ?? 16.0;
      _selectedFont = prefs.getString('fontStyle') ?? 'Quicksand';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Toggle
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: SwitchListTile(
              title: Text(
                'Dark Mode',
                style: GoogleFonts.quicksand(),
              ),
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: widget.onThemeChanged,
              secondary: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.nightlight_round
                    : Icons.wb_sunny,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Font Selection
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Font Style',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _fontOptions.length,
                      itemBuilder: (context, index) {
                        final font = _fontOptions[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ChoiceChip(
                            label: Text(
                              font,
                              style: GoogleFonts.getFont(
                                font,
                                fontSize: 14,
                              ),
                            ),
                            selected: _selectedFont == font,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedFont = font);
                                widget.onFontChanged(font);
                              }
                            },
                            selectedColor: Colors.deepPurple.withOpacity(0.2),
                            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Font Size Slider
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Font Size',
                    style: GoogleFonts.quicksand(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.text_fields, size: 20),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 12,
                          max: 24,
                          divisions: 6,
                          label: _fontSize.round().toString(),
                          onChanged: (value) {
                            setState(() => _fontSize = value);
                            widget.onFontSizeChanged(value);
                          },
                          activeColor: Colors.deepPurple,
                          inactiveColor: Colors.deepPurple.withOpacity(0.2),
                        ),
                      ),
                      const Icon(Icons.text_fields, size: 28),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Preview Text
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview',
                    style: GoogleFonts.quicksand(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The quick brown fox jumps over the lazy dog',
                    style: GoogleFonts.getFont(
                      _selectedFont,
                      fontSize: _fontSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}