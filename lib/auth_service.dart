import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  static const _userKey = 'storedUser';
  static const _passKey = 'storedPass';

  Future<bool> register(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, email);
      // Hash password before storing
      await prefs.setString(_passKey, _hashPassword(password));
      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = prefs.getString(_userKey);
      final storedPass = prefs.getString(_passKey);
      
      if (storedEmail == email && storedPass == _hashPassword(password)) {
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey) != null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_passKey);
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}