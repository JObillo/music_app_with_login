import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'navigation/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final FocusNode usernameFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;

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

  Future<bool> sendOtpEmail(String toEmail, String otp) async {
    String username = "obillojericho8@gmail.com";
    String password = "wrhx neqv emth fssd"; // Your Gmail App Password

    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username, 'Belle Music App')
      ..recipients.add(toEmail)
      ..subject = 'Your OTP for Login'
      ..text = 'Your OTP is: $otp';

    try {
      await send(message, smtpServer);
      return true;
    } catch (e) {
      print("Failed to send OTP: $e");
      return false;
    }
  }

  Future<void> sendLoginSuccessEmail(String toEmail, String firstname) async {
    String username = "obillojericho8@gmail.com";
    String password = "cele kttw nbkb palg"; // App Password

    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username, 'Belle Music App')
      ..recipients.add(toEmail)
      ..subject = 'Successful Login to Belle Music App'
      ..text =
          'Hello $firstname,\n\nYou have successfully logged in to Music App.\n\nEnjoy!';

    try {
      await send(message, smtpServer);
    } catch (e) {
      print("Failed to send login email: $e");
    }
  }

  Future<void> login() async {
    final input = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      _showError("Please enter username/email and password.");
      return;
    }

    if (otpLockedUntil != null && DateTime.now().isBefore(otpLockedUntil!)) {
      _showError(
        "Too many failed OTP attempts. Try again after ${otpLockedUntil!.difference(DateTime.now()).inHours} hours.",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      DocumentSnapshot<Map<String, dynamic>>? userDoc;
      String username = input;

      if (input.contains('@')) {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: input)
            .limit(1)
            .get();
        if (query.docs.isEmpty) throw "User not found";
        userDoc = query.docs.first;
        username = userDoc.id;
      } else {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(input)
            .get();
        if (!doc.exists) throw "User not found";
        userDoc = doc;
      }

      final data = userDoc.data()!;
      final storedHash = data['password'].toString();

      bool isPasswordCorrect;
      if (storedHash.startsWith(r'$2b$') || storedHash.startsWith(r'$2a$')) {
        isPasswordCorrect = BCrypt.checkpw(password, storedHash);
      } else {
        isPasswordCorrect = password == storedHash;
      }

      if (!isPasswordCorrect) throw "Wrong password";

      generatedOtp = (Random().nextInt(900000) + 100000).toString();
      otpAttempts = 0;

      final sent = await sendOtpEmail(data['email'], generatedOtp!);
      if (!sent) {
        _showError("Failed to send OTP. Try again.");
        return;
      }

      _showOtpDialog(data, username);
    } catch (_) {
      _showError("Invalid username/email or password");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOtpDialog(Map<String, dynamic> userData, String username) {
    final otpController = TextEditingController();
    int resendAttempts = 0;
    DateTime? resendLockedUntil;
    bool isVerifying = false;
    bool isResending = false;
    final parentContext = context;

    showDialog(
      barrierDismissible: false,
      context: parentContext,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Enter OTP"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
                          _showError("Too many OTP requests. Try again later.");
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

                        generatedOtp = (Random().nextInt(900000) + 100000)
                            .toString();
                        final sent = await sendOtpEmail(
                          userData['email'],
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
                        color: Color(0xFFB76E79),
                      ),
                    const SizedBox(width: 4),
                    const Text(
                      "Resend OTP",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB76E79),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
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
                      await Future.delayed(const Duration(milliseconds: 500));

                      if (otpController.text.trim() == generatedOtp) {
                        Navigator.of(context).pop();
                        _showSuccess("Welcome ${userData['firstname']}");

                        if (!mounted) return;
                        Future.delayed(
                          const Duration(milliseconds: 300),
                          () async {
                            await sendLoginSuccessEmail(
                              userData['email'],
                              userData['firstname'],
                            );
                            Navigator.of(parentContext).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => HomePage(
                                  firstname: userData['firstname'],
                                  lastname: userData['lastname'],
                                  username: username,
                                  email: userData['email'],
                                ),
                              ),
                            );
                          },
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

  void hideKeyboard() => FocusScope.of(context).unfocus();

  // SAME IMPORTS AS BEFORE (UNCHANGED)

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB76E79),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: usernameController,
                    focusNode: usernameFocus,
                    decoration: const InputDecoration(
                      labelText: "Username/Email",
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: passwordController,
                    focusNode: passwordFocus,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : login,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Login"),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/signup'),
                    child: const Text("Don't have an account? Sign up"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
