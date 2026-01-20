import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grim_app/app/routes/app_pages.dart';
import 'package:grim_app/app/services/auth_service.dart';
import 'package:flutter/material.dart';

class AuthController extends GetxController {
  final storage = GetStorage();
  final authService = Get.find<AuthService>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // Getters that delegate to AuthService
  bool get isLoggedIn => authService.isLoggedIn.value;
  String get userEmail => authService.userEmail.value;
  String get userName => authService.userName.value;
  bool get isOnline => authService.isOnline.value;
  String get authMethod => authService.authMethod.value;

  @override
  void onInit() {
    super.onInit();
    // AuthService handles initialization automatically
  }

  Future<bool> loginWithEmail(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Basic validation
      if (email.isEmpty || password.isEmpty) {
        errorMessage.value = 'Please fill in all fields';
        Get.snackbar(
          'Error',
          'Please fill in all fields',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      if (!GetUtils.isEmail(email)) {
        errorMessage.value = 'Please enter a valid email';
        Get.snackbar(
          'Error',
          'Please enter a valid email',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      final success = await authService.signInWithEmail(email, password);
      if (!success) {
        errorMessage.value = 'Invalid email or password';
        Get.snackbar(
          'Login Failed',
          'Invalid email or password',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        // Navigate to dashboard on successful login
        Get.offAllNamed('/dashboard');
      }
      return success;
    } catch (e) {
      errorMessage.value = 'Login failed: ${e.toString()}';
      Get.snackbar(
        'Login Error',
        'An unexpected error occurred',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Basic validation
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        errorMessage.value = 'Please fill in all fields';
        Get.snackbar(
          'Error',
          'Please fill in all fields',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      if (!GetUtils.isEmail(email)) {
        errorMessage.value = 'Please enter a valid email';
        Get.snackbar(
          'Error',
          'Please enter a valid email',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      if (password.length < 6) {
        errorMessage.value = 'Password must be at least 6 characters';
        Get.snackbar(
          'Error',
          'Password must be at least 6 characters',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      if (name.length < 2) {
        errorMessage.value = 'Name must be at least 2 characters';
        Get.snackbar(
          'Error',
          'Name must be at least 2 characters',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      final success = await authService.signUpWithEmail(email, password, name);
      if (!success) {
        errorMessage.value = 'Account creation failed';
        Get.snackbar(
          'Signup Failed',
          'Account creation failed. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Success',
          'Account created successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // Navigate to dashboard on successful signup
        Get.offAllNamed('/dashboard');
      }
      return success;
    } catch (e) {
      errorMessage.value = 'Signup failed: ${e.toString()}';
      Get.snackbar(
        'Signup Error',
        'An unexpected error occurred',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final success = await authService.signInWithGoogle();
      if (success) {
        Get.offAllNamed(Routes.dashboard);
      } else {
        errorMessage.value = 'Google sign-in failed';
        Get.snackbar(
          'Sign-In Failed',
          'Google sign-in failed. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      return success;
    } catch (e) {
      errorMessage.value = 'Google sign-in failed: ${e.toString()}';
      Get.snackbar(
        'Google Sign-In Error',
        'An unexpected error occurred',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      isLoading.value = true;
      await authService.signOut();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> syncWhenOnline() async {
    await authService.syncWhenOnline();
  }

  // Legacy methods for compatibility
  Future<void> login(String email, String password) async {
    await loginWithEmail(email, password);
  }

  Future<void> signup(String email, String password, String name) async {
    await signUpWithEmail(email, password, name);
  }

  Future<void> logout() async {
    await signOut();
  }

  // Legacy getter for compatibility
  Rxn<Map<String, dynamic>> get currentUser =>
      Rxn<Map<String, dynamic>>(authService.currentUser);
}

class User {
  String id;
  String email;
  String name;

  User({required this.id, required this.email, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'name': name};

  factory User.fromJson(Map<String, dynamic> json) =>
      User(id: json['id'], email: json['email'], name: json['name']);
}
