import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final firstnameController = TextEditingController();
  final lastnameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  final nameRegex = RegExp(r'^[a-zA-Z]+$');
  final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

  String? generatedOtp;
  int otpAttempts = 0;
  DateTime? otpLockedUntil;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  bool validateFields() {
    final firstname = firstnameController.text.trim();
    final lastname = lastnameController.text.trim();
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (firstname.isEmpty || !nameRegex.hasMatch(firstname)) {
      _showError("Invalid first name");
      return false;
    }

    if (lastname.isEmpty || !nameRegex.hasMatch(lastname)) {
      _showError("Invalid last name");
      return false;
    }

    if (username.isEmpty ||
        !usernameRegex.hasMatch(username) ||
        username.length < 4) {
      _showError("Invalid username");
      return false;
    }

    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      _showError("Invalid email");
      return false;
    }

    if (password.isEmpty || password.length < 6) {
      _showError("Password must be at least 6 characters");
      return false;
    }

    return true;
  }

  Future<void> signUp() async {
    if (!validateFields()) return;

    final username = usernameController.text.trim();
    final email = emailController.text.trim();

    // Check if username already exists
    final usernameDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(username)
        .get();

    if (usernameDoc.exists) {
      _showError("Username already exists");
      return;
    }

    // Check if email already used
    final emailQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (emailQuery.docs.isNotEmpty) {
      _showError("This email is already registered");
      return;
    }

    if (otpLockedUntil != null && DateTime.now().isBefore(otpLockedUntil!)) {
      _showError(
        "Too many failed attempts. Try again after ${otpLockedUntil!.difference(DateTime.now()).inHours} hours.",
      );
      return;
    }

    // Generate OTP
    generatedOtp = (Random().nextInt(900000) + 100000).toString();
    otpAttempts = 0;

    setState(() => _isLoading = true);

    final sent = await sendOtpEmail(email, generatedOtp!);

    setState(() => _isLoading = false);

    if (sent) {
      _showOtpDialog(
        FirebaseFirestore.instance.collection('users').doc(username),
      );
    } else {
      _showError("Failed to send OTP. Try again.");
    }
  }

  //12223212112
  Future<bool> sendOtpEmail(String toEmail, String otp) async {
    String username = "obillojericho8@gmail.com";
    String password = "wrhx neqv emth fssd";

    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username, 'Music App')
      ..recipients.add(toEmail)
      ..subject = 'Your OTP for Signup'
      ..text = 'Your OTP is: $otp';

    try {
      await send(message, smtpServer);
      return true;
    } catch (e) {
      print("Failed to send OTP: $e");
      return false;
    }
  }

  Future<void> sendSignupEmail(String toEmail, String firstname) async {
    String username = "obillojericho8@gmail.com";
    String password = "cele kttw nbkb palg";

    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username, 'Music App')
      ..recipients.add(toEmail)
      ..subject = 'Welcome to Music App!'
      ..text =
          'Hello $firstname,\n\nYou have successfully signed up and logged in to Music App.\n\nEnjoy!';

    try {
      await send(message, smtpServer);
    } catch (e) {
      print("Failed to send signup email: $e");
    }
  }

  void _showOtpDialog(DocumentReference userDocRef) {
    final otpController = TextEditingController();
    int resendAttempts = 0;
    DateTime? resendLockedUntil;
    bool isVerifying = false;
    bool isResending = false;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Verify OTP"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Enter OTP"),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: isResending
                    ? null
                    : () async {
                        setState(() => isResending = true);

                        if (resendLockedUntil != null &&
                            DateTime.now().isBefore(resendLockedUntil!)) {
                          _showError(
                            "Too many OTP requests. Try again in ${resendLockedUntil!.difference(DateTime.now()).inHours} hours.",
                          );
                          setState(() => isResending = false);
                          return;
                        }

                        if (resendAttempts >= 3) {
                          resendLockedUntil = DateTime.now().add(
                            const Duration(hours: 2),
                          );
                          _showError(
                            "Resend limit reached. Try again in 2 hours.",
                          );
                          setState(() => isResending = false);
                          return;
                        }

                        // Generate new OTP
                        generatedOtp = (Random().nextInt(900000) + 100000)
                            .toString();
                        final sent = await sendOtpEmail(
                          emailController.text.trim(),
                          generatedOtp!,
                        );

                        if (sent) {
                          resendAttempts++;
                          _showSuccess(
                            "OTP resent. Attempt $resendAttempts of 3",
                          );
                        } else {
                          _showError("Failed to resend OTP. Try again.");
                        }

                        setState(() => isResending = false);
                      },
                child: Row(
                  children: [
                    if (isResending)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (!isResending)
                      const Icon(
                        Icons.refresh,
                        size: 16,
                        color: Color(0xFF1877F2),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      "Resend OTP",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1877F2),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              if (otpLockedUntil != null &&
                  DateTime.now().isBefore(otpLockedUntil!))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Too many failed attempts. Try again later.",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: isVerifying
                  ? null
                  : () async {
                      setState(() => isVerifying = true);

                      await Future.delayed(
                        const Duration(milliseconds: 500),
                      ); // UX delay

                      if (otpController.text.trim() == generatedOtp) {
                        // Correct OTP, create user
                        final hashedPassword = BCrypt.hashpw(
                          passwordController.text.trim(),
                          BCrypt.gensalt(),
                        );

                        await userDocRef.set({
                          'firstname': firstnameController.text.trim(),
                          'lastname': lastnameController.text.trim(),
                          'username': usernameController.text.trim(),
                          'email': emailController.text.trim(),
                          'password': hashedPassword,
                        });

                        Navigator.of(context).pop();
                        _showSuccess(
                          "Welcome ${firstnameController.text.trim()}",
                        );

                        // Navigate to HomePage automatically
                        Navigator.pushReplacementNamed(
                          context,
                          '/home',
                          arguments: {
                            'firstname': firstnameController.text.trim(),
                            'lastname': lastnameController.text.trim(),
                            'username': usernameController.text.trim(),
                          },
                        );

                        // Send signup + login confirmation email
                        await sendSignupEmail(
                          emailController.text.trim(),
                          firstnameController.text.trim(),
                        );
                      } else {
                        otpAttempts++;
                        if (otpAttempts >= 3) {
                          otpLockedUntil = DateTime.now().add(
                            const Duration(hours: 2),
                          );
                          Navigator.of(context).pop();
                          _showError(
                            "Too many failed attempts. Try again in 2 hours.",
                          );
                        } else {
                          _showError(
                            "Incorrect OTP. Attempt $otpAttempts of 3",
                          );
                        }
                      }

                      setState(() => isVerifying = false);
                    },
              child: isVerifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Verify"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
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
              decoration: const InputDecoration(labelText: "First Name"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: lastnameController,
              decoration: const InputDecoration(labelText: "Last Name"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : signUp,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Signup"),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              child: const Text("Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}
