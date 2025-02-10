import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../repository/user_repository.dart';

class UserDataProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserRepository _userRepository;

  // User data
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> get userData => _userData;

  // User authentication state
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String _userEmail = '';
  String get userEmail => _userEmail;

  String _userId = '';
  String get userId => _userId;

  UserDataProvider({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository() {
    initializeUserData();
  }

  Future<void> initializeUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString('email') ?? '';
    _isLoggedIn = prefs.getBool('rememberMe') ?? false;
    _userId = _auth.currentUser?.uid ?? '';
    notifyListeners();

    if (_isLoggedIn && _userEmail.isNotEmpty) {
      await fetchUserData();
    }
  }

  // User Authentication Methods
  Future<bool> signInWithGoogle({bool rememberMe = false}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      await _firestore.collection('Users').doc(userCredential.user!.uid).set({
        'name': userCredential.user!.displayName,
        'email': userCredential.user!.email,
        'username': userCredential.user!.displayName ?? 'Kullanıcı Adı Yok',
      });

      if (rememberMe) {
        await _saveUserCredentials(
            userCredential.user!.email ?? '', rememberMe);
      }

      _userId = userCredential.user!.uid;
      _userEmail = userCredential.user!.email ?? '';
      _isLoggedIn = true;
      notifyListeners();
      await fetchUserData();

      return true;
    } catch (e) {
      print('Google sign in error: $e');
      return false;
    }
  }

  Future<bool> signInWithApple({bool rememberMe = false}) async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(oauthCredential);

      await _firestore.collection('Users').doc(userCredential.user!.uid).set({
        'name': appleCredential.givenName ?? 'Kullanıcı Adı Yok',
        'email': userCredential.user!.email ?? 'Email Yok',
        'username': appleCredential.givenName ?? 'Kullanıcı Adı Yok',
      });

      if (rememberMe) {
        await _saveUserCredentials(
            userCredential.user!.email ?? '', rememberMe);
      }

      _userId = userCredential.user!.uid;
      _userEmail = userCredential.user!.email ?? '';
      _isLoggedIn = true;
      notifyListeners();
      await fetchUserData();

      return true;
    } catch (e) {
      print('Apple sign in error: $e');
      return false;
    }
  }

  Future<bool> signInWithEmailPassword(String email, String password,
      {bool rememberMe = false}) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      if (rememberMe) {
        await _saveUserCredentials(email, rememberMe);
      }

      _userId = userCredential.user!.uid;
      _userEmail = email;
      _isLoggedIn = true;
      notifyListeners();
      await fetchUserData();

      return true;
    } catch (e) {
      print('Email/password sign in error: $e');
      return false;
    }
  }

  Future<bool> registerUser(String username, String email, String password,
      {bool rememberMe = false}) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore.collection('Users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
      });

      if (rememberMe) {
        await _saveUserCredentials(email, rememberMe);
      }

      _userId = userCredential.user!.uid;
      _userEmail = email;
      _isLoggedIn = true;
      notifyListeners();
      await fetchUserData();

      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      await clearUserData();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // User Data Methods
  Future<void> fetchUserData() async {
    try {
      if (_userId.isNotEmpty) {
        final docSnapshot =
            await _firestore.collection('Users').doc(_userId).get();
        if (docSnapshot.exists) {
          _userData = docSnapshot.data() ?? {};
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> updateUserData(Map<String, dynamic> newData) async {
    try {
      if (_userId.isNotEmpty) {
        await _firestore.collection('Users').doc(_userId).update(newData);
        await fetchUserData();
      }
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  Future<void> deleteUserAccount() async {
    try {
      if (_userId.isNotEmpty) {
        await _firestore.collection('Users').doc(_userId).delete();
        await _auth.currentUser?.delete();
        await clearUserData();
      }
    } catch (e) {
      print('Error deleting user account: $e');
      rethrow;
    }
  }

  // Helper Methods
  Future<void> _saveUserCredentials(String email, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', rememberMe);
    await prefs.setString('email', email);
  }

  Future<void> clearUserData() async {
    _userData = {};
    _userEmail = '';
    _userId = '';
    _isLoggedIn = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> addWeight(double weight) async {
    try {
      await _userRepository.addWeight(weight);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding weight: $e');
      return false;
    }
  }

  Future<bool> editWeight(String id, double weight) async {
    try {
      await _userRepository.editWeight(id, weight);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error editing weight: $e');
      return false;
    }
  }

  Future<void> updateLastProgram(String programId) async {
    try {
      await _userRepository.updateLastProgram(programId);
      notifyListeners();
    } catch (e) {
      print('Error updating last program: $e');
    }
  }

  Future<void> fetchPrograms(
      BuildContext context,
      List<Map<String, dynamic>> programs,
      String lastProgramName,
      String nextProgramName) async {
    try {
      await _userRepository.fetchPrograms(
          context, programs, lastProgramName, nextProgramName);
      notifyListeners();
    } catch (e) {
      print('Error fetching programs: $e');
    }
  }

  Future<void> fetchNextProgram(String uid, List<Map<String, dynamic>> programs,
      String lastProgramName, String nextProgramName) async {
    try {
      await _userRepository.fetchNextProgram(
          uid, programs, lastProgramName, nextProgramName);
      notifyListeners();
    } catch (e) {
      print('Error fetching next program: $e');
    }
  }
}
