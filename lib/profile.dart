import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

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

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  File? _profileImage;
  DateTime? _birthDate;
  int _dreamCount = 0;

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('userName') ?? '';
      _bioController.text = prefs.getString('userBio') ?? '';
      _dreamCount = prefs.getInt('dreamCount') ?? 0;
      final birthDateString = prefs.getString('birthDate');
      if (birthDateString != null) {
        _birthDate = DateTime.parse(birthDateString);
      }
      final imagePath = prefs.getString('profileImagePath');
      if (imagePath != null) {
        _profileImage = File(imagePath);
      }
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text);
    await prefs.setString('userBio', _bioController.text);
    if (_birthDate != null) {
      await prefs.setString('birthDate', _birthDate!.toIso8601String());
    }
    if (_profileImage != null) {
      await prefs.setString('profileImagePath', _profileImage!.path);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile saved successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.deepPurple,
              surface: const Color(0xFF1A1A2E),
            ),
            dialogBackgroundColor: const Color(0xFF0F0B21),
          ),
          child: child ?? Container(),
        );
      },
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B21),
      body: LiquidPullToRefresh(
        onRefresh: _loadProfile,
        color: Colors.deepPurple,
        height: 150,
        animSpeedFactor: 2,
        showChildOpacityTransition: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'My Profile',
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
                background: _profileImage != null
                    ? Image.file(_profileImage!, fit: BoxFit.cover)
                    : Container(
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
                  icon: const Icon(Icons.save),
                  onPressed: _saveProfile,
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: GlassContainer(
                        blur: 10,
                        borderRadius: 75,
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.transparent,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? const Icon(Icons.add_a_photo, size: 40)
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassContainer(
                    blur: 10,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            style: GoogleFonts.quicksand(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Name',
                              labelStyle: const TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                          ),
                          Divider(color: Colors.white.withOpacity(0.2)),
                          TextField(
                            controller: _bioController,
                            style: GoogleFonts.quicksand(color: Colors.white),
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Bio',
                              labelStyle: const TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassContainer(
                    blur: 10,
                    child: ListTile(
                      title: Text('Birth Date',
                        style: GoogleFonts.quicksand(color: Colors.white70)),
                      subtitle: Text(
                        _birthDate != null
                            ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                            : 'Not set',
                        style: GoogleFonts.quicksand(color: Colors.white),
                      ),
                      trailing: const Icon(Icons.calendar_today, color: Colors.white70),
                      onTap: () => _selectBirthDate(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassContainer(
                    blur: 10,
                    child: ListTile(
                      title: Text('Dreams Recorded',
                        style: GoogleFonts.quicksand(color: Colors.white70)),
                      subtitle: Text(_dreamCount.toString(),
                        style: GoogleFonts.quicksand(
                          color: Colors.deepPurpleAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: const Icon(Icons.auto_awesome, 
                        color: Colors.deepPurpleAccent),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}