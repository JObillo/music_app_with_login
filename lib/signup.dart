import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController emailOrUsernameController =
      TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    emailOrUsernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signUp(
    String firstname,
    String lastname,
    String emailOrUsername,
    String password,
  ) async {
    try {
      final email = emailOrUsername.contains('@')
          ? emailOrUsername
          : '$emailOrUsername@example.com';
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user!.updateDisplayName('$firstname $lastname');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully signup as $emailOrUsername!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = '';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The email/username already exists.';
      } else {
        message = e.message ?? 'Signup failed.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signup Page')),
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: firstnameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: lastnameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailOrUsernameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email or Username',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  String firstname = firstnameController.text.trim();
                  String lastname = lastnameController.text.trim();
                  String emailOrUsername = emailOrUsernameController.text
                      .trim();
                  String password = passwordController.text.trim();

                  if (firstname.isEmpty ||
                      lastname.isEmpty ||
                      emailOrUsername.isEmpty ||
                      password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please fill all fields.',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  await signUp(firstname, lastname, emailOrUsername, password);
                },
                child: const Text('Signup'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: const Text("Already have an account? Login here"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
//2