import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/firebaseuse.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;
  User? get currentUser => _service.currentUser;
  Stream<User?> get authStateChanges => _service.authStateChanges;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _begin() {
    _loading = true;
    _error = null;
    notifyListeners();
  }

  void _end({String? error}) {
    _loading = false;
    _error = error;
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String studentId,
  }) async {
    _begin();
    try {
      await _service.signUp(
        email: email,
        password: password,
        fullName: fullName,
        studentId: studentId,
      );
      _end();
      return true;
    } on FirebaseAuthException catch (e) {
      _end(error: _service.friendlyError(e));
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _begin();
    try {
      await _service.signIn(email: email, password: password);
      _end();
      return true;
    } on FirebaseAuthException catch (e) {
      _end(error: _service.friendlyError(e));
      return false;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    notifyListeners();
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _begin();
    try {
      await _service.sendPasswordResetEmail(email);
      _end();
      return true;
    } on FirebaseAuthException catch (e) {
      _end(error: _service.friendlyError(e));
      return false;
    }
  }

  Future<bool> resendVerificationEmail() async {
    _begin();
    try {
      await _service.resendVerificationEmail();
      _end();
      return true;
    } catch (e) {
      _end(error: 'Could not resend email. Try again later.');
      return false;
    }
  }

  Future<bool> reloadAndCheckVerified() async {
    return await _service.reloadAndCheckVerified();
  }
}
