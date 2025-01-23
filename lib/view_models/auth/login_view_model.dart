import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:social/screens/mainscreen.dart';
import 'package:social/services/auth_service.dart';
import 'package:social/splash_screen.dart';
import 'package:social/utils/validation.dart';

import '../../AdminPanel.dart'; // Import Admin Panel

class LoginViewModel extends ChangeNotifier {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool validate = false;
  bool loading = false;
  String? email, password;
  FocusNode emailFN = FocusNode();
  FocusNode passFN = FocusNode();
  AuthService auth = AuthService();

  // Login method
  login(BuildContext context) async {
    FormState form = formKey.currentState!;
    form.save();
    if (!form.validate()) {
      validate = true;
      notifyListeners();
      showInSnackBar('Please fix the errors in red before submitting.', context);
    } else {
      loading = true;
      notifyListeners();
      try {
        // Check for admin credentials
        if (email == 'admin@gmail.com' && password == 'admin@123') {
          Navigator.of(context).pushReplacement(
              CupertinoPageRoute(builder: (_) => AdminPanel())); // Navigate to Admin Panel
        } else {
          // Regular user login
          bool success = await auth.loginUser(
            email: email,
            password: password,
          );
          if (success) {
            Navigator.of(context).pushReplacement(
                CupertinoPageRoute(builder: (_) => SplashScreen())); // Regular user home screen
          }
        }
      } catch (e) {
        loading = false;
        notifyListeners();
        print(e);
        showInSnackBar('${auth.handleFirebaseAuthError(e.toString())}', context);
      }
      loading = false;
      notifyListeners();
    }
  }

  // Forgot Password method
  forgotPassword(BuildContext context) async {
    loading = true;
    notifyListeners();
    FormState form = formKey.currentState!;
    form.save();
    if (Validations.validateEmail(email) != null) {
      showInSnackBar('Please input a valid email to reset your password.', context);
    } else {
      try {
        await auth.forgotPassword(email!);
        showInSnackBar('Please check your email for instructions to reset your password', context);
      } catch (e) {
        showInSnackBar('${e.toString()}', context);
      }
    }
    loading = false;
    notifyListeners();
  }

  // Set Email and Password
  setEmail(val) {
    email = val;
    notifyListeners();
  }

  setPassword(val) {
    password = val;
    notifyListeners();
  }

  // Show SnackBar message
  void showInSnackBar(String value, context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
