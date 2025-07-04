import 'package:flutter/material.dart';
import 'sql_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _journals = [];
  bool _isLoading = true;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await SQLHelper.printDbPath();
      await SQLHelper.database; // Initialize database
      await _refreshJournals();
    } catch (e) {
      _showError('Failed to initialize app: $e');
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

  Future<void> _addItem() async {
    if (_titleController.text.isEmpty) {
      _showError('Title cannot be empty');
      return;
    }

    try {
      await SQLHelper.createItem(
        _titleController.text,
        _descriptionController.text,
      );
      _titleController.clear();
      _descriptionController.clear();
      await _refreshJournals();
      _showMessage('Entry created successfully');
    } catch (e) {
      _showError('Failed to create entry: $e');
    }
  }

  Future<void> _updateItem(int id) async {
    try {
      await SQLHelper.updateItem(
        id,
        _titleController.text,
        _descriptionController.text,
      );
      _titleController.clear();
      _descriptionController.clear();
      await _refreshJournals();
      _showMessage('Entry updated successfully');
    } catch (e) {
      _showError('Failed to update entry: $e');
    }
  }

  Future<void> _deleteItem(int id) async {
    try {
      await SQLHelper.deleteItem(id);
      await _refreshJournals();
      _showMessage('Entry deleted successfully');
    } catch (e) {
      _showError('Failed to delete entry: $e');
    }
  }

  void _showForm(int? id) {
    if (id != null) {
      final existingJournal = _journals.firstWhere((element) => element['id'] == id);
      _titleController.text = existingJournal['title'];
      _descriptionController.text = existingJournal['description'];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                if (id == null) {
                  await _addItem();
                } else {
                  await _updateItem(id);
                }
              },
              child: Text(id == null ? 'Create' : 'Update'),
            )
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Diary'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _journals.isEmpty
              ? const Center(child: Text('No entries yet. Tap + to add one!'))
              : ListView.builder(
                  itemCount: _journals.length,
                  itemBuilder: (context, index) {
                    final journal = _journals[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(journal['title']),
                        subtitle: Text(journal['description']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showForm(journal['id']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteItem(journal['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}