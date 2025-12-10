import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  String? _selectedGender;
  String? _selectedSkinType;
  bool _agreeTerms = false;
  bool _newsletterSubscription = true;
  bool showPassword = false;
  bool isLoading = false;
  bool isHoveringLogin = false;

  final List<String> _genders = ['Male', 'Female', 'Prefer not to say'];
  final List<String> _skinTypes = [
    'Normal',
    'Dry',
    'Oily',
    'Combination',
    'Sensitive',
    'Acne-Prone'
  ];

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    addressController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isStrongPassword(String password) {
    return password.length >= 6;
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^\+62[0-9]{9,12}$').hasMatch(phone);
  }

  String _formatPhone(String phone) {
    if (phone.startsWith('0')) {
      return '+62${phone.substring(1)}';
    } else if (phone.startsWith('62')) {
      return '+$phone';
    } else if (!phone.startsWith('+62')) {
      return '+62$phone';
    }
    return phone;
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) {
      _alert("Please fill all required fields correctly!");
      return;
    }

    if (!_agreeTerms) {
      _alert("You must agree to the terms and conditions!");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _alert("Passwords do not match!");
      return;
    }

    final formattedPhone = _formatPhone(phoneController.text.trim());
    if (!_isValidPhone(formattedPhone)) {
      _alert("Phone number must be in +62 format (e.g., +628123456789)");
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential user = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.user!.uid)
          .set({
        "fullName": fullNameController.text.trim(),
        "phone": formattedPhone,
        "email": emailController.text.trim(),
        "address": addressController.text.trim(),
        "gender": _selectedGender ?? "Prefer not to say",
        "skinType": _selectedSkinType ?? "Normal",
        "newsletterSubscription": _newsletterSubscription,
        "createdAt": FieldValue.serverTimestamp(),
      });

      _alert("🎉 Registration successful! Redirecting to login...", success: true);

      await Future.delayed(const Duration(milliseconds: 2000));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );

    } on FirebaseAuthException catch (e) {
      String errorMessage = "Registration failed!";
      if (e.code == 'email-already-in-use') {
        errorMessage = "Email already registered! Please use another email.";
      } else if (e.code == 'weak-password') {
        errorMessage = "Password is too weak! Use at least 6 characters.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email format!";
      } else {
        errorMessage = e.message ?? "Registration error!";
      }
      _alert(errorMessage);
    } catch (e) {
      _alert("Unexpected error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _alert(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: success ? 3 : 4),
      ),
    );
  }

  void goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
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
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(top: 40, bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4EC),
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: const Color(0xFFFFB6C1),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1,
                    size: 60,
                    color: Color(0xFFFF6B9D),
                  ),
                ),

                const Text(
                  'Join My Skincare Family! 🌸',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                    fontFamily: 'ComicNeue',
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                const Text(
                  'Create your account to unlock all the cute features!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFFFF0F5),
                      width: 2,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: fullNameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name *',
                            hintText: 'Enter your full name',
                            prefixIcon: const Icon(Icons.person, color: Color(0xFFFF6B9D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.pink.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFFF0F5).withOpacity(0.5),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Full name is required';
                            }
                            if (value.length < 3) {
                              return 'Name must be at least 3 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: InputDecoration(
                            labelText: 'Gender *',
                            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFFF6B9D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.pink.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFFF0F5).withOpacity(0.5),
                          ),
                          items: _genders.map((gender) {
                            return DropdownMenuItem(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedGender = value);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select your gender';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number *',
                            hintText: '0812-3456-7890',
                            prefixIcon: const Icon(Icons.phone, color: Color(0xFFFF6B9D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.pink.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFFF0F5).withOpacity(0.5),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Phone number is required';
                            }
                            if (value.length < 10) {
                              return 'Phone number must be at least 10 digits';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address *',
                            hintText: 'example@email.com',
                            prefixIcon: const Icon(Icons.email, color: Color(0xFFFF6B9D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.pink.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFFF0F5).withOpacity(0.5),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!_isValidEmail(value.trim())) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: addressController,
                          decoration: InputDecoration(
                            labelText: 'Full Address *',
                            hintText: 'Street, City, Postal Code',
                            prefixIcon: const Icon(Icons.home, color: Color(0xFFFF6B9D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.pink.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFFF0F5).withOpacity(0.5),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Address is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        DropdownButtonFormField<String>(
                          value: _selectedSkinType,
                          decoration: InputDecoration(
                            labelText: 'Skin Type *',
                            prefixIcon: const Icon(Icons.spa, color: Color(0xFF00CED1)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.pink.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Color(0xFF00CED1), width: 2),
                            ),
                            helperText: 'We\'ll recommend skincare just for you!',
                            helperStyle: TextStyle(color: Colors.pink[600], fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFFF0F8FF).withOpacity(0.5),
                          ),
                          items: _skinTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedSkinType = value);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select your skin type';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password *',
                            hintText: 'Create a strong password',
                            prefixIcon: const Icon(Icons.lock, color: Color(0xFFFF6B9D)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPassword ? Icons.visibility : Icons.visibility_off,
                                color: const Color(0xFFFF6B9D),
                              ),
                              onPressed: () {
                                setState(() => showPassword = !showPassword);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.pink.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFFF0F5).withOpacity(0.5),
                          ),
                          obscureText: !showPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (!_isStrongPassword(value)) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password *',
                            hintText: 'Re-enter your password',
                            prefixIcon: const Icon(Icons.lock_reset, color: Color(0xFFFF6B9D)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPassword ? Icons.visibility : Icons.visibility_off,
                                color: const Color(0xFFFF6B9D),
                              ),
                              onPressed: () {
                                setState(() => showPassword = !showPassword);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.pink.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFFF0F5).withOpacity(0.5),
                          ),
                          obscureText: !showPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Checkbox(
                              value: _newsletterSubscription,
                              onChanged: (value) {
                                setState(() => _newsletterSubscription = value ?? false);
                              },
                              activeColor: const Color(0xFFFF6B9D),
                              checkColor: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Subscribe to our skincare newsletter 💌',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            Checkbox(
                              value: _agreeTerms,
                              onChanged: (value) {
                                setState(() => _agreeTerms = value ?? false);
                              },
                              activeColor: const Color(0xFFFF6B9D),
                              checkColor: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: 'I agree to the ',
                                  style: TextStyle(fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: 'Terms',
                                      style: TextStyle(
                                        color: Color(0xFF6A5ACD),
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: Color(0xFF6A5ACD),
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: ' *'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

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
                            onPressed: isLoading ? null : register,
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
                                Icon(Icons.person_add_alt_1, size: 22),
                                SizedBox(width: 12),
                                Text(
                                  'Create My Account',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account? ",
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 14,
                              ),
                            ),
                            MouseRegion(
                              onEnter: (_) => setState(() => isHoveringLogin = true),
                              onExit: (_) => setState(() => isHoveringLogin = false),
                              child: GestureDetector(
                                onTap: goToLogin,
                                child: Text(
                                  "Login Here",
                                  style: TextStyle(
                                    color: isHoveringLogin
                                        ? const Color(0xFFFF6B9D)
                                        : const Color(0xFF6A5ACD),
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            '← Back to Home',
                            style: TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  '🌸 Start your skincare journey with us! ✨',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}