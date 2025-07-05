import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'sql_helper.dart';

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

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  List<Map<String, dynamic>> _journals = [];
  bool _isLoading = true;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final Random _random = Random();
  bool _isSaving = false;
  int _dreamCount = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _initializeApp();
    _loadDreamCount();
  }

  Future<void> _loadDreamCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dreamCount = prefs.getInt('dreamCount') ?? 0;
    });
  }

  Future<void> _updateDreamCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dreamCount = _journals.length;
      prefs.setInt('dreamCount', _dreamCount);
    });
  }

  Future<void> _initializeApp() async {
    try {
      final db = await SQLHelper.database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='journals'"
      );
      
      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE journals(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
      }
      await _refreshJournals();
    } catch (e) {
      _showError('Failed to initialize app: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshJournals() async {
    try {
      final data = await SQLHelper.getItems();
      if (mounted) {
        setState(() => _journals = data);
        _updateDreamCount();
      }
    } catch (e) {
      _showError('Failed to load entries: ${e.toString()}');
    }
  }

  Future<void> _addItem() async {
    if (_titleController.text.isEmpty) {
      _showError('Title cannot be empty');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final id = await SQLHelper.createItem(
        _titleController.text,
        _descriptionController.text,
      );
      
      if (id > 0) {
        _titleController.clear();
        _descriptionController.clear();
        await _refreshJournals();
        _confettiController.play();
        _showMessage('Memory saved successfully! ✨');
      } else {
        _showError('Failed to save memory');
      }
    } catch (e) {
      _showError('Error saving memory: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _updateItem(int id) async {
    if (_titleController.text.isEmpty) {
      _showError('Title cannot be empty');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final rowsAffected = await SQLHelper.updateItem(
        id,
        _titleController.text,
        _descriptionController.text,
      );
      
      if (rowsAffected > 0) {
        _titleController.clear();
        _descriptionController.clear();
        await _refreshJournals();
        _showMessage('Memory updated successfully!');
      } else {
        _showError('Failed to update memory');
      }
    } catch (e) {
      _showError('Error updating memory: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDelete(int id) async {
    return showDialog(
      context: context,
      builder: (context) => GlassContainer(
        blur: 15,
        child: AlertDialog(
          title: Text('Delete Entry', style: GoogleFonts.quicksand(color: Colors.white)),
          content: Text('Are you sure?', style: GoogleFonts.quicksand(color: Colors.white70)),
          backgroundColor: Colors.transparent,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.quicksand(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteItem(id);
              },
              child: Text('Delete', style: GoogleFonts.quicksand(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem(int id) async {
    try {
      final rowsAffected = await SQLHelper.deleteItem(id);
      if (rowsAffected > 0) {
        await _refreshJournals();
        _showMessage('Memory deleted successfully');
      } else {
        _showError('Failed to delete memory');
      }
    } catch (e) {
      _showError('Error deleting memory: ${e.toString()}');
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.deepPurple,
              surface: Color(0xFF1A1A2E),
            ),
            dialogBackgroundColor: Color(0xFF0F0B21),
          ),
          child: child ?? Container(), // Fixed missing child parameter
        );
      },
    );
    if (picked != null) {
      // Handle the selected date
    }
  }

  void _showForm(int? id) {
    if (id != null) {
      final existingJournal = _journals.firstWhere((element) => element['id'] == id);
      _titleController.text = existingJournal['title'];
      _descriptionController.text = existingJournal['description'] ?? '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GlassContainer(
        blur: 15,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Text(
                id == null ? '✨ New Memory' : '✏️ Edit Memory',
                style: GoogleFonts.quicksand(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      backgroundColor: Colors.deepPurple.withOpacity(0.8),
                    ),
                    onPressed: _isSaving ? null : () async {
                      Navigator.pop(context);
                      if (id == null) {
                        await _addItem();
                      } else {
                        await _updateItem(id);
                      }
                    },
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            id == null ? 'Save Memory' : 'Update',
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.auto_awesome,
          size: 60,
          color: Colors.deepPurple.withOpacity(0.5),
        ),
        const SizedBox(height: 20),
        Text(
          'No dreams recorded yet!\nTap the + button to begin',
          textAlign: TextAlign.center,
          style: GoogleFonts.quicksand(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> journal, BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: _journals.indexOf(journal),
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: GlassContainer(
              blur: 10,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showForm(journal['id']),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              journal['title'],
                              style: GoogleFonts.quicksand(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white70),
                            onPressed: () => _confirmDelete(journal['id']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        journal['description'] ?? '',
                        style: GoogleFonts.quicksand(
                          color: Colors.white70,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            journal['createdAt'] != null 
                                ? journal['createdAt'].toString().substring(0, 10)
                                : '',
                            style: GoogleFonts.quicksand(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B21),
      body: Stack(
        children: [
          CustomPaint(
            painter: _StarsPainter(random: _random),
            size: Size.infinite,
          ),
          
          LiquidPullToRefresh(
            onRefresh: _refreshJournals,
            color: Colors.deepPurple,
            height: 150,
            animSpeedFactor: 2,
            showChildOpacityTransition: false,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 100,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Dream Diary',
                      style: GoogleFonts.quicksand(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.deepPurple.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.deepPurple.withOpacity(0.7),
                            Colors.purple.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  pinned: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () => Navigator.pushNamed(context, '/settings'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person),
                      onPressed: () => Navigator.pushNamed(context, '/profile'),
                    ),
                  ],
                ),
                
                _isLoading
                    ? SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Shimmer.fromColors(
                              baseColor: Colors.deepPurple.withOpacity(0.2),
                              highlightColor: Colors.deepPurple.withOpacity(0.4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.auto_awesome, size: 50),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Loading your dreams...',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : _journals.isEmpty
                        ? SliverToBoxAdapter(
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: _buildEmptyState(),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return _buildJournalCard(_journals[index], context);
                                },
                                childCount: _journals.length,
                              ),
                            ),
                          ),
              ],
            ),
          ),
          
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.purple,
              Colors.deepPurple,
              Colors.blue,
              Colors.pink,
            ],
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(null),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple,
                Colors.purpleAccent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.add, size: 30),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class _StarsPainter extends CustomPainter {
  final Random random;
  
  const _StarsPainter({required this.random});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 150; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5;
      final opacity = random.nextDouble() * 0.5 + 0.1;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}