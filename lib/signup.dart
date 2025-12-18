import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'navigation/home_page.dart';

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
  final otpController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? generatedOtp;

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
    const username = "misalangbelle@gmail.com";
    const password = "dkqs jpyc bwjy qyuw"; // Replace with your app password

    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username, 'Belle Music App')
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
    const username = "misalangbelle@gmail.com";
    const password = "poiw pslf kbaz vjyl"; // Replace with your app password

    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username, 'Belle Music App')
      ..recipients.add(toEmail)
      ..subject = 'Welcome to Belle Music App!'
      ..text =
          'Hello $firstname,\n\nYou have successfully signed up and logged in to belle Music App.\n\nEnjoy!';

    try {
      await send(message, smtpServer);
    } catch (e) {
      print("Failed to send signup email: $e");
    }
  }

  Future<void> signup() async {
    final firstname = firstnameController.text.trim();
    final lastname = lastnameController.text.trim();
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (firstname.isEmpty ||
        lastname.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(username)
          .get();
      if (userDoc.exists) throw "Username already exists";

      final emailQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (emailQuery.docs.isNotEmpty) throw "Email already used";

      generatedOtp = (Random().nextInt(900000) + 100000).toString();
      final sent = await sendOtpEmail(email, generatedOtp!);
      if (!sent) {
        _showError("Failed to send OTP. Try again.");
        return;
      }

      _showOtpDialog(firstname, lastname, username, email, password);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showOtpDialog(
    String firstname,
    String lastname,
    String username,
    String email,
    String password,
  ) {
    int attempts = 0;
    bool isVerifying = false;
    bool isResending = false;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Enter OTP"),
          content: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Enter OTP"),
          ),
          actions: [
            // Verify Button with loading
            ElevatedButton(
              onPressed: isVerifying
                  ? null
                  : () async {
                      setState(() => isVerifying = true);
                      await Future.delayed(
                        const Duration(milliseconds: 200),
                      ); // small delay for UI update

                      if (otpController.text.trim() == generatedOtp) {
                        final hashedPassword = BCrypt.hashpw(
                          password,
                          BCrypt.gensalt(),
                        );

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(username)
                            .set({
                              "firstname": firstname,
                              "lastname": lastname,
                              "username": username,
                              "email": email,
                              "password": hashedPassword,
                            });

                        await sendSignupEmail(email, firstname);

                        _showSuccess("Account created successfully!");
                        Navigator.of(context).pop();

                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomePage(
                              firstname: firstname,
                              lastname: lastname,
                              username: username,
                              email: email,
                            ),
                          ),
                        );
                      } else {
                        attempts++;
                        if (attempts >= 3) {
                          Navigator.of(context).pop();
                          _showError(
                            "Too many failed attempts. Try again later.",
                          );
                        } else {
                          _showError("Incorrect OTP. Attempt $attempts of 3");
                        }
                      }
                      setState(() => isVerifying = false);
                    },
              child: isVerifying
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Verify"),
            ),
            // Resend Button with loading
            TextButton(
              onPressed: isResending
                  ? null
                  : () async {
                      setState(() => isResending = true);
                      generatedOtp = (Random().nextInt(900000) + 100000)
                          .toString();
                      final sent = await sendOtpEmail(email, generatedOtp!);
                      if (sent) {
                        _showSuccess("OTP resent successfully!");
                      } else {
                        _showError("Failed to resend OTP. Try again.");
                      }
                      setState(() => isResending = false);
                    },
              child: isResending
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Resend OTP"),
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
    otpController.dispose();
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
                    "Create Account",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB76E79),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: firstnameController,
                    decoration: const InputDecoration(labelText: "First Name"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: lastnameController,
                    decoration: const InputDecoration(labelText: "Last Name"),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: "Username"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: passwordController,
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
                      onPressed: _isLoading ? null : signup,

                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Sign Up"),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text("Already have an account? Login"),
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
