import 'package:shared_preferences/shared_preferences.dart';

class CurrentUserSession {
  CurrentUserSession._();

  static final CurrentUserSession instance = CurrentUserSession._();
  static const String _currentUserEmailKey = 'session.current_user_email';

  String? _currentUserEmail;

  String? get currentUserEmail => _currentUserEmail;

  Future<void> setCurrentUserEmail(String email) async {
    _currentUserEmail = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserEmailKey, _currentUserEmail!);
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString(_currentUserEmailKey);
    if (storedEmail == null || storedEmail.trim().isEmpty) {
      _currentUserEmail = null;
      return;
    }
    _currentUserEmail = storedEmail.trim().toLowerCase();
  }

  Future<void> clear() async {
    _currentUserEmail = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserEmailKey);
  }
}
