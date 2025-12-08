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

  final FocusNode firstnameFocus = FocusNode();
  final FocusNode lastnameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  bool _obscurePassword = true;

  @override
  void dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    emailOrUsernameController.dispose();
    passwordController.dispose();

    firstnameFocus.dispose();
    lastnameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();

    super.dispose();
  }

  void hideKeyboard() => FocusScope.of(context).unfocus();

  Future<void> signUp(
    String firstname,
    String lastname,
    String emailOrUsername,
    String password,
  ) async {
    if (firstname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your first name.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (lastname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your last name.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (emailOrUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your email or username.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your password.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
            'Successfully signed up as $emailOrUsername!',
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
      body: GestureDetector(
        onTap: hideKeyboard,
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: firstnameController,
                  focusNode: firstnameFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(lastnameFocus),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: lastnameController,
                  focusNode: lastnameFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(emailFocus),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailOrUsernameController,
                  focusNode: emailFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(passwordFocus),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email or Username',
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  focusNode: passwordFocus,
                  textInputAction: TextInputAction.done,
                  obscureText: _obscurePassword,
                  onSubmitted: (_) async {
                    hideKeyboard();
                    await signUp(
                      firstnameController.text.trim(),
                      lastnameController.text.trim(),
                      emailOrUsernameController.text.trim(),
                      passwordController.text.trim(),
                    );
                  },
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
                    hideKeyboard();
                    await signUp(
                      firstnameController.text.trim(),
                      lastnameController.text.trim(),
                      emailOrUsernameController.text.trim(),
                      passwordController.text.trim(),
                    );
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
      ),
    );
  }
}
//4