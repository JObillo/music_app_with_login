import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final firstnameController = TextEditingController();
  final lastnameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final firstnameFocus = FocusNode();
  final lastnameFocus = FocusNode();
  final usernameFocus = FocusNode();
  final passwordFocus = FocusNode();

  String? firstnameError;
  String? lastnameError;
  String? usernameError;
  String? passwordError;

  bool _isLoading = false;
  bool _obscurePassword = true;

  final nameRegex = RegExp(r'^[a-zA-Z]+$');
  final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');

  @override
  void initState() {
    super.initState();

    firstnameFocus.addListener(() {
      if (!firstnameFocus.hasFocus) {
        validateFirstname();
      }
    });

    lastnameFocus.addListener(() {
      if (!lastnameFocus.hasFocus) {
        validateLastname();
      }
    });

    usernameFocus.addListener(() {
      if (!usernameFocus.hasFocus) {
        validateUsername();
      }
    });

    passwordFocus.addListener(() {
      if (!passwordFocus.hasFocus) {
        validatePassword();
      }
    });
  }

  void validateFirstname() {
    final value = firstnameController.text.trim();
    if (value.isEmpty) {
      firstnameError = "First name is required";
    } else if (!nameRegex.hasMatch(value)) {
      firstnameError = "Letters only";
    } else {
      firstnameError = null;
    }
    setState(() {});
  }

  void validateLastname() {
    final value = lastnameController.text.trim();
    if (value.isEmpty) {
      lastnameError = "Last name is required";
    } else if (!nameRegex.hasMatch(value)) {
      lastnameError = "Letters only";
    } else {
      lastnameError = null;
    }
    setState(() {});
  }

  void validateUsername() {
    final value = usernameController.text.trim();
    if (value.isEmpty) {
      usernameError = "Username is required";
    } else if (!usernameRegex.hasMatch(value)) {
      usernameError = "Only letters, numbers, and underscore (_) allowed";
    } else if (value.length < 4) {
      usernameError = "At least 4 characters required";
    } else {
      usernameError = null;
    }
    setState(() {});
  }

  void validatePassword() {
    final value = passwordController.text.trim();
    if (value.isEmpty) {
      passwordError = "Password is required";
    } else if (value.length < 6) {
      passwordError = "At least 6 characters required";
    } else {
      passwordError = null;
    }
    setState(() {});
  }

  Future<void> signUp() async {
    validateFirstname();
    validateLastname();
    validateUsername();
    validatePassword();

    if (firstnameError != null ||
        lastnameError != null ||
        usernameError != null ||
        passwordError != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final username = usernameController.text.trim();

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(username);

      final doc = await docRef.get();
      if (doc.exists) {
        _showError("Username already exists");
        return;
      }

      final hashedPassword = BCrypt.hashpw(
        passwordController.text.trim(),
        BCrypt.gensalt(),
      );

      await docRef.set({
        'firstname': firstnameController.text.trim(),
        'lastname': lastnameController.text.trim(),
        'username': username,
        'password': hashedPassword,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Signup successful"),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    usernameController.dispose();
    passwordController.dispose();

    firstnameFocus.dispose();
    lastnameFocus.dispose();
    usernameFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Signup Page")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            TextField(
              controller: firstnameController,
              focusNode: firstnameFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(lastnameFocus),
              decoration: InputDecoration(
                labelText: "First Name",
                errorText: firstnameError,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: lastnameController,
              focusNode: lastnameFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(usernameFocus),
              decoration: InputDecoration(
                labelText: "Last Name",
                errorText: lastnameError,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: usernameController,
              focusNode: usernameFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(passwordFocus),
              decoration: InputDecoration(
                labelText: "Username",
                errorText: usernameError,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              focusNode: passwordFocus,
              textInputAction: TextInputAction.done,
              obscureText: _obscurePassword,
              onSubmitted: (_) => signUp(),
              decoration: InputDecoration(
                labelText: "Password",
                errorText: passwordError,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : signUp,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Signup"),
            ),
          ],
        ),
      ),
    );
  }
}
