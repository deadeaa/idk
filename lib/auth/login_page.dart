import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_page.dart';
import 'rive_widget.dart';
import 'forgot_password.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  final GlobalKey<RiveLoginControllerState> riveKey = GlobalKey();

  bool isLoading = false;
  bool isHoveringRegister = false;
  bool isPasswordVisible = false;
  bool isHoveringForgotPassword = false;

  @override
  void initState() {
    super.initState();
    emailFocus.addListener(() {
      riveKey.currentState?.setFocus(emailFocus.hasFocus);
    });
    passwordFocus.addListener(() {
      riveKey.currentState?.setPassword(passwordFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showSnackBar("Please fill all fields 🌸", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      riveKey.currentState?.loginSuccess();

      _showSnackBar("Welcome back! 🎉✨", isError: false);

      await Future.delayed(const Duration(milliseconds: 800));

      Navigator.pushReplacementNamed(context, '/dashboard');

    } on FirebaseAuthException catch (e) {
      riveKey.currentState?.loginFail();

      String errorMessage = "Login failed 😢";
      if (e.code == 'user-not-found') {
        errorMessage = "No account found with this email 📭";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Oops! Wrong password 🔐";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Please enter a valid email 📧";
      } else if (e.code == 'user-disabled') {
        errorMessage = "This account has been disabled ⚠️";
      } else if (e.code == 'too-many-requests') {
        errorMessage = "Too many attempts. Try again later ⏰";
      } else {
        errorMessage = "Error: ${e.message}";
      }

      _showSnackBar(errorMessage, isError: true);

    } catch (e) {
      riveKey.currentState?.loginFail();
      _showSnackBar("An unexpected error occurred 🌧️", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFFF6B9D) : const Color(0xFF81C784),
        duration: Duration(seconds: isError ? 3 : 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  void goToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
    );
  }

  void goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF0F5),
              Color(0xFFF0F8FF),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 300,
                child: RiveLoginController(
                  key: riveKey,
                  riveFile: 'assets/animation/animated-bunny.riv',
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFFFF0F5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, color: Color(0xFFFF6B9D), size: 28),
                          SizedBox(width: 10),
                          Text(
                            "Welcome Back!",
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ComicNeue',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Login to continue your skincare journey ✨",
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 30),

                      TextField(
                        controller: emailController,
                        focusNode: emailFocus,
                        style: const TextStyle(color: Color(0xFF333333)),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFFFF0F5).withOpacity(0.7),
                          labelText: 'Email Address',
                          labelStyle: const TextStyle(color: Color(0xFFFF6B9D)),
                          hintText: 'your@email.com',
                          hintStyle: TextStyle(color: Colors.pink.shade300),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFFFF6B9D),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: Colors.pink.shade200,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6B9D),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: Colors.pink.shade100,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: passwordController,
                        focusNode: passwordFocus,
                        obscureText: !isPasswordVisible,
                        style: const TextStyle(color: Color(0xFF333333)),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFFFF0F5).withOpacity(0.7),
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Color(0xFFFF6B9D)),
                          hintText: 'Enter your password',
                          hintStyle: TextStyle(color: Colors.pink.shade300),
                          prefixIcon: const Icon(
                            Icons.lock_outlined,
                            color: Color(0xFFFF6B9D),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFFFF6B9D),
                            ),
                            onPressed: () {
                              setState(() => isPasswordVisible = !isPasswordVisible);
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: Colors.pink.shade200,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6B9D),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: Colors.pink.shade100,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      MouseRegion(
                        onEnter: (_) =>
                            setState(() => isHoveringForgotPassword = true),
                        onExit: (_) =>
                            setState(() => isHoveringForgotPassword = false),
                        child: GestureDetector(
                          onTap: goToForgotPassword,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isHoveringForgotPassword
                                  ? const Color(0xFFFCE4EC)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.help_outline,
                                  size: 16,
                                  color: isHoveringForgotPassword
                                      ? const Color(0xFFFF6B9D)
                                      : const Color(0xFF666666),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: isHoveringForgotPassword
                                        ? const Color(0xFFFF6B9D)
                                        : const Color(0xFF666666),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B9D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login, size: 22),
                              SizedBox(width: 12),
                              Text(
                                'Login to My Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 1,
                            width: 60,
                            color: const Color(0xFFE0E0E0),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "New here?",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            height: 1,
                            width: 60,
                            color: const Color(0xFFE0E0E0),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF6A5ACD),
                            width: 2,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: goToRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF6A5ACD),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_alt_1, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Create New Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/dashboard');
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.home_outlined,
                                color: Color(0xFF999999), size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Back to Home',
                              style: TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDot(const Color(0xFFFFB6C1)),
                        const SizedBox(width: 8),
                        _buildDot(const Color(0xFFFFD700)),
                        const SizedBox(width: 8),
                        _buildDot(const Color(0xFF87CEEB)),
                        const SizedBox(width: 8),
                        _buildDot(const Color(0xFF98FB98)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your skincare journey starts here! 🌸',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}