import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isHoveringBack = false;
  bool _showSuccessMessage = false;

  Future<void> _sendPasswordReset() async {
    if (_emailController.text.isEmpty) {
      _showMessage("Please enter your email");
      return;
    }

    final email = _emailController.text.trim();

    if (!_isValidEmail(email)) {
      _showMessage("Please enter a valid email address");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      setState(() => _showSuccessMessage = true);
      _showMessage("✅ Password reset email sent! Check your inbox.", isSuccess: true);

    } on FirebaseAuthException catch (e) {
      String errorMessage = "Failed to send reset email";

      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No account found with this email";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email address format";
          break;
        case 'too-many-requests':
          errorMessage = "Too many attempts. Please try again later";
          break;
        case 'network-request-failed':
          errorMessage = "Network error. Check your connection";
          break;
        default:
          errorMessage = "Error: ${e.message}";
      }

      _showMessage(errorMessage);
    } catch (e) {
      _showMessage("An unexpected error occurred");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showMessage(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? Colors.green : const Color(0xFFFF6B9D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: Duration(seconds: isSuccess ? 4 : 3),
      ),
    );
  }

  void _goBackToLogin() {
    Navigator.pop(context);
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
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF6B9D),
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        size: 60,
                        color: Color(0xFFFF6B9D),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Reset Password",
                      style: TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ComicNeue',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showSuccessMessage
                          ? "Check your email for reset link ✉️"
                          : "Enter your email to receive password reset link 🔐",
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: Container(
                  padding: const EdgeInsets.all(24),
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
                      if (!_showSuccessMessage) ...[
                        TextField(
                          controller: _emailController,
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
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFD54F)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFFFFB300), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "We'll send a password reset link to this email",
                                      style: TextStyle(
                                        color: const Color(0xFFE65100),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Check your spam folder if you don't see it",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                            onPressed: _isLoading ? null : _sendPasswordReset,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B9D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
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
                                Icon(Icons.email, size: 22),
                                SizedBox(width: 12),
                                Text(
                                  'Send Reset Link',
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
                        MouseRegion(
                          onEnter: (_) => setState(() => _isHoveringBack = true),
                          onExit: (_) => setState(() => _isHoveringBack = false),
                          child: GestureDetector(
                            onTap: _goBackToLogin,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _isHoveringBack
                                    ? const Color(0xFFFCE4EC)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_back,
                                    size: 16,
                                    color: _isHoveringBack
                                        ? const Color(0xFFFF6B9D)
                                        : const Color(0xFF666666),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Back to Login",
                                    style: TextStyle(
                                      color: _isHoveringBack
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
                        const SizedBox(height: 10),
                        Text(
                          "Make sure to enter the email associated with your account",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (_showSuccessMessage) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFA5D6A7)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 50),
                              const SizedBox(height: 16),
                              const Text(
                                "Email Sent Successfully!",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "We've sent a password reset link to:\n${_emailController.text}",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInstructionItem("📧 Check your inbox (and spam folder)"),
                                  _buildInstructionItem("🔗 Click the password reset link"),
                                  _buildInstructionItem("🔒 Create a new password"),
                                  _buildInstructionItem("✅ Login with your new password"),
                                ],
                              ),
                              const SizedBox(height: 25),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _showSuccessMessage = false;
                                          _emailController.clear();
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF666666),
                                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                      ),
                                      child: const Text("Try Another Email"),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _goBackToLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4CAF50),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                      ),
                                      child: const Text("Back to Login"),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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
                      'Your skincare journey continues here! 🌸',
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

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}