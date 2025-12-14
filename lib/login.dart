import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'navigation/home_page.dart';
import 'package:bcrypt/bcrypt.dart';

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

  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter username and password."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(username)
          .get();

      if (!doc.exists) throw "User not found";

      final data = doc.data()!;
      final storedHash = data['password'].toString();

      bool isPasswordCorrect;

      if (storedHash.startsWith(r'$2b$') || storedHash.startsWith(r'$2a$')) {
        // Password is hashed
        isPasswordCorrect = BCrypt.checkpw(password, storedHash);
      } else {
        // Old plain text password
        isPasswordCorrect = password == storedHash;
      }

      if (!isPasswordCorrect) throw "Wrong password";

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Welcome back, ${data['firstname']}!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(
              firstname: data['firstname'],
              lastname: data['lastname'],
              username: data['username'],
            ),
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid username or password"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void hideKeyboard() => FocusScope.of(context).unfocus();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Page")),
      body: GestureDetector(
        onTap: hideKeyboard,
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: usernameController,
                  focusNode: usernameFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(passwordFocus);
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Username"),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  focusNode: passwordFocus,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => login(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Password",
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
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Login"),
                ),
                const SizedBox(height: 20),
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
    );
  }
}
