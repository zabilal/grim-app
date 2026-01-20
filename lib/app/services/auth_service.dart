import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends GetxService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final storage = GetStorage();

  // Reactive variables
  final isLoggedIn = false.obs;
  final userEmail = ''.obs;
  final userName = ''.obs;
  final userAvatar = ''.obs;
  final isOnline = false.obs;
  final authMethod = 'none'.obs; // 'google', 'local', 'none'

  // Local user data
  auth.User? _firebaseUser;
  Map<String, dynamic>? _localUserData;

  @override
  void onInit() {
    super.onInit();
    _initializeAuth();
    _checkConnectivity();
  }

  Future<void> _initializeAuth() async {
    // Check for existing Firebase session
    _firebaseUser = _auth.currentUser;

    // Load local user data
    _localUserData = storage.read('local_user');

    // Determine authentication state
    if (_firebaseUser != null) {
      _setFirebaseUser(_firebaseUser!);
    } else if (_localUserData != null) {
      _setLocalUser(_localUserData!);
    }

    // Listen to Firebase auth changes
    _auth.authStateChanges().listen((auth.User? user) {
      if (user != null) {
        _setFirebaseUser(user);
      } else if (_localUserData != null) {
        _setLocalUser(_localUserData!);
      } else {
        _clearUser();
      }
    });
  }

  void _checkConnectivity() {
    // Start with online assumption, let actual operations determine status
    isOnline.value = true;

    // Periodic connectivity check using Firebase Auth
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        // Simple check - try to get current user (doesn't require network)
        _auth.currentUser;

        // Optional: lightweight network check
        await Future.delayed(Duration(milliseconds: 100));
        isOnline.value = true;
      } catch (e) {
        // Only set offline if there's a genuine network error
        isOnline.value = false;
      }
    });
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      if (isOnline.value) {
        // Online: Try Firebase first
        final auth.UserCredential result = await _auth
            .signInWithEmailAndPassword(email: email, password: password);

        // Sync local data with Firebase
        await _syncFromCloud(result.user!);
        return true;
      } else {
        // Offline: Check local authentication
        final localUser = storage.read('local_user');
        if (localUser != null &&
            localUser['email'] == email &&
            localUser['password'] == _hashPassword(password)) {
          _setLocalUser(localUser);
          return true;
        }
        return false;
      }
    } catch (e) {
      print('Email sign in error: $e');
      return false;
    }
  }

  Future<bool> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      if (isOnline.value) {
        // Online: Create Firebase account
        final auth.UserCredential result = await _auth
            .createUserWithEmailAndPassword(email: email, password: password);

        // Update user profile
        await result.user?.updateDisplayName(name);

        // Create user document in Firestore
        await _firestore.collection('users').doc(result.user!.uid).set({
          'email': email,
          'name': name,
          'createdAt': DateTime.now().toIso8601String(),
          'authMethod': 'email',
        });

        // Create local backup
        final localUser = {
          'email': email,
          'password': _hashPassword(password),
          'name': name,
          'authMethod': 'email',
          'createdAt': DateTime.now().toIso8601String(),
        };
        storage.write('local_user', localUser);

        return true;
      } else {
        // Offline: Create local account only
        final localUser = {
          'email': email,
          'password': _hashPassword(password),
          'name': name,
          'authMethod': 'email',
          'createdAt': DateTime.now().toIso8601String(),
        };
        storage.write('local_user', localUser);
        _setLocalUser(localUser);
        return true;
      }
    } on auth.FirebaseAuthException catch (e) {
      print('Email sign up error: $e');
      Get.snackbar(
        'Signup Error',
        e.message ?? 'Account creation failed',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      print('Email sign up error: $e');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      if (!isOnline.value) {
        Get.snackbar(
          'Offline Mode',
          'Google Sign-In requires internet connection. Please use email/password or connect to internet.',
          backgroundColor: Colors.orange,
        );
        return false;
      }

      // Sign out from Google first to ensure clean state
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
        // Add this to help with authentication
        signInOption: SignInOption.standard,
      );

      // Sign out from previous session
      await googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Check if we have the required tokens
      if (googleAuth.idToken == null) {
        Get.snackbar(
          'Google Sign-In Error',
          'Failed to get authentication token',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // Create a new credential - FIX: Use OAuthCredential instead of AuthCredential
      final auth.OAuthCredential credential =
          auth.GoogleAuthProvider.credential(
            idToken: googleAuth.idToken,
            accessToken: googleAuth.accessToken,
          );

      // Sign in to Firebase with the credential
      final auth.UserCredential result = await _auth.signInWithCredential(
        credential,
      );

      final auth.User? user = result.user;

      if (user != null) {
        // Create/update user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'name': user.displayName ?? 'User',
          'avatar': user.photoURL ?? '',
          'authMethod': 'google',
          'lastLogin': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        // Create local backup
        final localUser = {
          'email': user.email,
          'name': user.displayName ?? 'User',
          'avatar': user.photoURL ?? '',
          'authMethod': 'google',
          'createdAt': DateTime.now().toIso8601String(),
        };
        storage.write('local_user', localUser);

        Get.snackbar(
          'Success',
          'Signed in successfully with Google',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        return true;
      }
      return false;
    } on auth.FirebaseAuthException catch (e) {
      print('Firebase Auth error: ${e.code} - ${e.message}');
      Get.snackbar(
        'Authentication Error',
        e.message ?? 'Failed to sign in with Google',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      print('Google sign in error: $e');
      Get.snackbar(
        'Google Sign-In Error',
        'An unexpected error occurred',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      if (_firebaseUser != null) {
        await _auth.signOut();
      }

      // Clear local data
      storage.remove('local_user');
      _clearUser();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  Future<void> syncWhenOnline() async {
    if (!isOnline.value || _localUserData == null) return;

    try {
      final localUser = _localUserData!;

      if (localUser['authMethod'] == 'email' && _firebaseUser == null) {
        // Try to create Firebase account from local data
        try {
          final auth.UserCredential
          result = await _auth.createUserWithEmailAndPassword(
            email: localUser['email'],
            password:
                localUser['password'], // This won't work with hashed password
          );

          // Sync data to Firebase
          await _syncToCloud(result.user!);
        } catch (e) {
          print('Failed to sync local account to Firebase: $e');
        }
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }

  void _setFirebaseUser(auth.User user) {
    _firebaseUser = user;
    isLoggedIn.value = true;
    userEmail.value = user.email ?? '';
    userName.value = user.displayName ?? 'User';
    userAvatar.value = user.photoURL ?? '';
    authMethod.value = 'google';
  }

  void _setLocalUser(Map<String, dynamic> userData) {
    _localUserData = userData;
    isLoggedIn.value = true;
    userEmail.value = userData['email'] ?? '';
    userName.value = userData['name'] ?? 'User';
    userAvatar.value = userData['avatar'] ?? '';
    authMethod.value = userData['authMethod'] ?? 'local';
  }

  void _clearUser() {
    _firebaseUser = null;
    _localUserData = null;
    isLoggedIn.value = false;
    userEmail.value = '';
    userName.value = '';
    userAvatar.value = '';
    authMethod.value = 'none';
  }

  String _hashPassword(String password) {
    // Simple hash for demo (use proper crypto in production)
    return password.hashCode.toString();
  }

  Future<void> _syncToCloud(auth.User user) async {
    try {
      // Sync all local data to Firebase
      final goals = storage.read('goals') ?? [];
      final tasks = storage.read('execution_tasks') ?? [];
      final settings = storage.read('settings') ?? {};

      await _firestore.collection('users').doc(user.uid).set({
        'goals': goals,
        'tasks': tasks,
        'settings': settings,
        'lastSync': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Cloud sync error: $e');
    }
  }

  Future<void> _syncFromCloud(auth.User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // Sync data to local storage
        if (data['goals'] != null) {
          storage.write('goals', data['goals']);
        }
        if (data['tasks'] != null) {
          storage.write('execution_tasks', data['tasks']);
        }
        if (data['settings'] != null) {
          storage.write('settings', data['settings']);
        }
      }
    } catch (e) {
      print('Cloud sync error: $e');
    }
  }

  // Get current user info
  Map<String, dynamic> get currentUser {
    if (_firebaseUser != null) {
      return {
        'email': _firebaseUser!.email,
        'name': _firebaseUser!.displayName,
        'avatar': _firebaseUser!.photoURL,
        'authMethod': 'google',
      };
    } else if (_localUserData != null) {
      return {
        'email': _localUserData!['email'],
        'name': _localUserData!['name'],
        'avatar': _localUserData!['avatar'],
        'authMethod': _localUserData!['authMethod'],
      };
    }
    return {};
  }

  bool get isGoogleUser => authMethod.value == 'google';
  bool get isLocalUser =>
      authMethod.value == 'email' || authMethod.value == 'local';
}
