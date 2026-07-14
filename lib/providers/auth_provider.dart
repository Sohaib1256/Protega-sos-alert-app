import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider; // hide to avoid conflict if any
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class AuthProvider with ChangeNotifier {
  static const _uuid = Uuid();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  
  UserModel? get currentUser => _currentUser;
  double get userLat => _currentUser?.lat ?? 0.0;
  double get userLng => _currentUser?.lng ?? 0.0;
  
  String? get uid => _auth.currentUser?.uid;

  AuthProvider() {
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        fetchCurrentUser();
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> fetchCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _currentUser = UserModel(
          id: data['id'] ?? 'Unknown',
          name: data['name'] ?? 'Unknown',
          email: data['email'] ?? user.email!,
          role: parseRole(data['role']),
          phone: data['phone'] ?? '',
          guardianPhone: data['guardianPhone'],
          occupation: data['occupation'],
          avatarUrl: data['avatarUrl'],
          isOnline: true,
          lat: data['lat'],
          lng: data['lng'],
          deviceConfigured: data['deviceConfigured'] ?? false,
          deviceId: data['deviceId'],
          friends: List<String>.from(data['friends'] ?? []),
          sentRequests: List<String>.from(data['sentRequests'] ?? []),
          receivedRequests: List<String>.from(data['receivedRequests'] ?? []),
        );
        notifyListeners();
      }
    }
  }

  void updateCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  UserRole parseRole(String? roleStr) {
    switch (roleStr) {
      case 'user': return UserRole.user;
      case 'guardian': return UserRole.guardian;
      case 'patient': return UserRole.user;
      case 'caretaker': return UserRole.user;
      case 'safetyOfficer': return UserRole.user;
      default: return UserRole.user;
    }
  }

  Future<String?> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return 'Please fill in all fields';
    }
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await fetchCurrentUser();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'No user found for that email.';
      if (e.code == 'wrong-password') return 'Wrong password provided.';
      if (e.code == 'invalid-credential') return 'Invalid email or password.';  
      return 'Login failed: ${e.message}';
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _auth.signOut();
    notifyListeners();
  }

  Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? guardianPhone,
    String? phone,
  }) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return 'Please fill in all fields';
    }
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String idPrefix = role == UserRole.guardian ? 'GID' : 'UID';
      final customId = '$idPrefix-${_uuid.v4().substring(0, 6).toUpperCase()}';
      
      final newUser = UserModel(
        id: customId,
        name: name,
        email: email,
        role: role,
        guardianPhone: guardianPhone,
        phone: phone ?? '',
        occupation: role == UserRole.user ? 'User' : 'Guardian',
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'id': newUser.id,
        'name': newUser.name,
        'email': newUser.email,
        'role': newUser.role.toString().split('.').last,
        'phone': newUser.phone,
        'guardianPhone': newUser.guardianPhone,
        'occupation': newUser.occupation,
        'avatarUrl': newUser.avatarUrl,
        'isOnline': true,
        'friends': [],
        'sentRequests': [],
        'receivedRequests': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      _currentUser = newUser;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') return 'The password provided is too weak.';
      if (e.code == 'email-already-in-use') return 'The account already exists for that email.';
      return 'Signup failed: ${e.message}';
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  void updateProfile({
    String? name,
    String? email,
    String? phone,
    String? occupation,
    int? age,
    String? avatarUrl,
  }) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        name: name,
        email: email,
        phone: phone,
        occupation: occupation,
        age: age,
        avatarUrl: avatarUrl,
      );
      notifyListeners();
    }
  }
}
