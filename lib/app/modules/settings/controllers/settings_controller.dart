import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsController extends GetxController {
  final storage = GetStorage();

  final cloudSyncEnabled = false.obs;
  final notificationsEnabled = true.obs;
  final strictModeEnabled = true.obs;
  final blockSocialMedia = true.obs;
  final deepWorkHours = 4.obs;
  final isLoggedIn = false.obs;
  final userEmail = ''.obs;
  final syncStatus = 'Not synced'.obs;
  final lastSyncTime = ''.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  @override
  void onInit() {
    super.onInit();
    loadSettings();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.signInSilently();
    } catch (e) {
      print('Google Sign-In initialization error: $e');
    }
  }

  void loadSettings() {
    cloudSyncEnabled.value = storage.read('cloudSync') ?? false;
    notificationsEnabled.value = storage.read('notifications') ?? true;
    strictModeEnabled.value = storage.read('strictMode') ?? true;
    blockSocialMedia.value = storage.read('blockSocial') ?? true;
    deepWorkHours.value = storage.read('deepWorkHours') ?? 4;
  }

  void toggleCloudSync() async {
    cloudSyncEnabled.value = !cloudSyncEnabled.value;
    storage.write('cloudSync', cloudSyncEnabled.value);

    if (cloudSyncEnabled.value) {
      await _signInWithGoogle();
    } else {
      await _signOutGoogle();
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      syncStatus.value = 'Signing in...';

      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        syncStatus.value = 'Sign in cancelled';
        Get.snackbar(
          'Cloud Sync',
          'Sign in cancelled',
          backgroundColor: Colors.orange,
        );
        cloudSyncEnabled.value = false;
        return;
      }

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        isLoggedIn.value = true;
        userEmail.value = firebaseUser.email ?? '';

        // Sync data to cloud
        await _syncDataToCloud();

        // Sync data to cloud
        await _syncDataFromCloud();

        Get.snackbar(
          'Cloud Sync',
          'Successfully signed in and synced!',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      syncStatus.value = 'Sign in failed';
      cloudSyncEnabled.value = false;
      Get.snackbar(
        'Cloud Sync',
        'Failed to sign in: $e',
        backgroundColor: Colors.red,
      );
      print('Google Sign-In Error: $e');
    }
  }

  Future<void> _signOutGoogle() async {
    try {
      syncStatus.value = 'Signing out...';

      await _googleSignIn.signOut();
      await _auth.signOut();

      isLoggedIn.value = false;
      userEmail.value = '';
      syncStatus.value = 'Not synced';

      Get.snackbar(
        'Cloud Sync',
        'Successfully signed out',
        backgroundColor: Colors.blue,
      );
    } catch (e) {
      syncStatus.value = 'Sign out failed';
      Get.snackbar(
        'Cloud Sync',
        'Failed to sign out: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _syncDataToCloud() async {
    try {
      syncStatus.value = 'Syncing data...';

      final User? user = _auth.currentUser;
      if (user == null) return;

      // Get all local data
      final goalsData = storage.read('goals') ?? [];
      final tasksData = storage.read('execution_tasks') ?? [];
      final topGoalsData = storage.read('top_goals_per_day') ?? {};

      // Sync to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'lastSync': DateTime.now().toIso8601String(),
        'goals': goalsData,
        'tasks': tasksData,
        'topGoals': topGoalsData,
        'settings': {
          'notifications': notificationsEnabled.value,
          'strictMode': strictModeEnabled.value,
          'blockSocial': blockSocialMedia.value,
          'deepWorkHours': deepWorkHours.value,
        },
      }, SetOptions(merge: true));

      lastSyncTime.value = DateTime.now().toString().substring(0, 16);
      syncStatus.value = 'Synced';
    } catch (e) {
      syncStatus.value = 'Sync failed';
      Get.snackbar(
        'Cloud Sync',
        'Failed to sync data: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _syncDataFromCloud() async {
    try {
      syncStatus.value = 'Downloading data...';

      final User? user = _auth.currentUser;
      if (user == null) return;

      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        // Download goals
        if (data['goals'] != null) {
          storage.write('goals', data['goals']);
        }

        // Download tasks
        if (data['tasks'] != null) {
          storage.write('execution_tasks', data['tasks']);
        }

        // Download top goals
        if (data['topGoals'] != null) {
          storage.write('top_goals_per_day', data['topGoals']);
        }

        // Download settings
        if (data['settings'] != null) {
          final settings = data['settings'] as Map<String, dynamic>;
          notificationsEnabled.value = settings['notifications'] ?? true;
          strictModeEnabled.value = settings['strictMode'] ?? true;
          blockSocialMedia.value = settings['blockSocial'] ?? true;
          deepWorkHours.value = settings['deepWorkHours'] ?? 4;
        }

        lastSyncTime.value =
            data['lastSync']?.toString().substring(0, 16) ?? '';
        syncStatus.value = 'Downloaded';

        Get.snackbar(
          'Cloud Sync',
          'Data downloaded successfully!',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      syncStatus.value = 'Download failed';
      Get.snackbar(
        'Cloud Sync',
        'Failed to download data: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> manualSync() async {
    if (!isLoggedIn.value) {
      Get.snackbar(
        'Cloud Sync',
        'Please sign in first',
        backgroundColor: Colors.orange,
      );
      return;
    }

    await _syncDataToCloud();
  }

  void toggleNotifications() {
    notificationsEnabled.value = !notificationsEnabled.value;
    storage.write('notifications', notificationsEnabled.value);
  }

  void toggleStrictMode() {
    strictModeEnabled.value = !strictModeEnabled.value;
    storage.write('strictMode', strictModeEnabled.value);
  }

  void toggleBlockSocialMedia() {
    blockSocialMedia.value = !blockSocialMedia.value;
    storage.write('blockSocial', blockSocialMedia.value);
  }

  void setDeepWorkHours(int hours) {
    deepWorkHours.value = hours;
    storage.write('deepWorkHours', hours);
  }
}
