import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class AuthViewModel extends ChangeNotifier {
  UserRole? selectedRole;

  bool isLoading = false;
  String? error;

  // In a real app these come from API/Firebase
  UserModel? currentUser;

  void selectRole(UserRole role) {
    selectedRole = role;
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (selectedRole == null) {
      error = "Please select a role first.";
      notifyListeners();
      return false;
    }
    isLoading = true;
    error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600)); // demo

    // Demo "created user"
    currentUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      email: email.trim(),
      role: selectedRole!,
      isActive: true,
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> login({required String email, required String password}) async {
    if (selectedRole == null) {
      error = "Please select a role first.";
      notifyListeners();
      return false;
    }
    isLoading = true;
    error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500)); // demo

    // Demo "logged user"
    currentUser = UserModel(
      id: "demo",
      name: selectedRole == UserRole.deaf ? "Deaf User" : "Caregiver",
      email: email.trim(),
      role: selectedRole!,
      isActive: true,
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  void logout() {
    currentUser = null;
    selectedRole = null;
    notifyListeners();
  }
}
