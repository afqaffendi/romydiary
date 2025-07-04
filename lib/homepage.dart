import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:confetti/confetti.dart';
import 'sql_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ConfettiController _confettiController;
  List<Map<String, dynamic>> _journals = [];
  bool _isLoading = true;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await SQLHelper.database; // initialize DB
      await _refreshJournals();
    } catch (e) {
      _showError('Failed to initialize: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshJournals() async {
    try {
      final data = await SQLHelper.getItems();
      setState(() => _journals = data);
    } catch (e) {
      _showError('Failed to load entries: $e');
    }
  }

  Future<void> _handleRefresh() async {
    await _refreshJournals();
  }

  Future<void> _addItem() async {
    try {
      await SQLHelper.createItem(
        _titleController.text,
        _descriptionController.text,
      );
      await _refreshJournals();
      _confettiController.play();
    } catch (e) {
      _showError('Failed to add memory: $e');
    }
  }

  Future<void> _updateItem(int id) async {
    try {
      await SQLHelper.updateItem(
        id,
        _titleController.text,
        _descriptionController.text,
      );
      await _refreshJournals();
    } catch (e) {
      _showError('Failed to update memory: $e');
    }
  }

  Future<void> _deleteItem(int id) async {
    try {
      await SQLHelper.deleteItem(id);
      await _refreshJournals();
    } catch (e) {
      _showError('Failed to delete memory: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showForm(int? id) {
    if (id == null) {
      // New entry — clear controllers
      _titleController.clear();
      _descriptionController.clear();
    } else {
      // Editing existing entry — fill controllers
      final existingJournal =
          _journals.firstWhere((element) => element['id'] == id);
      _titleController.text = existingJournal['title'];
      _descriptionController.text = existingJournal['description'];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 5,
            )
          ],
        ),
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              id == null ? 'New Memory' : 'Edit Memory',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                if (id == null) {
                  await _addItem();
                } else {
                  await _updateItem(id);
                }
              },
              child: Text(
                id == null ? 'Save Memory' : 'Update',
                style: const TextStyle(fontSize: 16),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(null),
        child: const Icon(Icons.add, size: 28),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
      ),
      body: Stack(
        children: [
          LiquidPullToRefresh(
            onRefresh: _handleRefresh,
            color: Theme.of(context).primaryColor,
            height: 150,
            animSpeedFactor: 2,
            showChildOpacityTransition: false,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 150,
                  flexibleSpace: FlexibleSpaceBar(
                    title: AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          'Dream Diary',
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          speed: const Duration(milliseconds: 100),
                        ),
                      ],
                      totalRepeatCount: 1,
                    ),
                    background: Image.asset(
                      'assets/image/diary_bg.jpeg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  pinned: true,
                ),
                _isLoading
                    ? const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _journals.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.book,
                                    size: 60,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'No memories yet!\nTap + to add your first entry',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final journal = _journals[index];
                                return Card(
                                  margin: const EdgeInsets.all(12),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(15),
                                    onTap: () => _showForm(journal['id']),
                                    onLongPress: () => showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Memory'),
                                        content: const Text(
                                            'Are you sure you want to delete this memory?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(ctx).pop();
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.of(ctx).pop();
                                              await _deleteItem(journal['id']);
                                            },
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            journal['title'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            journal['description'],
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                journal['createdAt']
                                                    .toString()
                                                    .substring(0, 10),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: _journals.length,
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
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ],
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
