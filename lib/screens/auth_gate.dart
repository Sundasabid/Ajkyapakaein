import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';

class AuthGate extends StatefulWidget {
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Controllers for text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool showPassword = false;
  bool rememberMe = false;
  bool isLogin = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkRememberedUser();
  }

  // Check if user should be remembered and auto-login
  Future<void> _checkRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldRemember = prefs.getBool('remember_me') ?? false;

    if (shouldRemember && FirebaseAuth.instance.currentUser != null) {
      // Check if user is verified before auto-login
      if (FirebaseAuth.instance.currentUser!.emailVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    }
  }

  // Firebase Login - only for verified users
  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showCustomDialog("Missing Information", "Please fill in all fields to continue.", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check if email is verified
      if (!userCredential.user!.emailVerified) {
        // Send verification email
        await userCredential.user!.sendEmailVerification();
        _showCustomDialog(
            "Email Verification Required",
            "Please check your email and verify your account before logging in. We've sent a new verification link to ${_emailController.text.trim()}",
            isError: true
        );
        await FirebaseAuth.instance.signOut();
      } else {
        // Save remember me preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', rememberMe);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showCustomDialog("Login Failed", _getErrorMessage(e.code), isError: true);
    } catch (e) {
      _showCustomDialog("Error", "Something went wrong. Please check your internet connection and try again.", isError: true);
    }

    setState(() => isLoading = false);
  }

  // Firebase Signup with email verification
  Future<void> _signup() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showCustomDialog("Missing Information", "Please fill in all fields to create your account.", isError: true);
      return;
    }

    if (_passwordController.text.trim().length < 6) {
      _showCustomDialog("Weak Password", "Password should be at least 6 characters long.", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Update display name
      await userCredential.user!.updateDisplayName(_nameController.text.trim());

      // Send verification email
      await userCredential.user!.sendEmailVerification();

      _showCustomDialog(
          "Account Created Successfully!",
          "Welcome ${_nameController.text.trim()}! We've sent a verification email to ${_emailController.text.trim()}. Please verify your email before logging in.",
          isError: false,
          onClose: () {
            setState(() => isLogin = true);
            _emailController.clear();
            _passwordController.clear();
            _nameController.clear();
          }
      );

    } on FirebaseAuthException catch (e) {
      _showCustomDialog("Signup Failed", _getErrorMessage(e.code), isError: true);
    } catch (e) {
      _showCustomDialog("Error", "Something went wrong. Please check your internet connection and try again.", isError: true);
    }

    setState(() => isLoading = false);
  }

  // Get user-friendly error messages
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in instead.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  // Forgot Password functionality
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      _showCustomDialog(
        "Email Required", 
        "Please enter your email address to reset your password.", 
        isError: true
      );
      return;
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showCustomDialog(
        "Invalid Email", 
        "Please enter a valid email address.", 
        isError: true
      );
      return;
    }

    try {
      setState(() => isLoading = true);
      
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      setState(() => isLoading = false);
      
      _showCustomDialog(
        "Password Reset Email Sent",
        "A password reset link has been sent to $email. Please check your email and follow the instructions to reset your password.",
        isError: false,
        onClose: () {
          // Navigate back to login screen after success
          setState(() {
            isLogin = true;
            _emailController.clear();
            _passwordController.clear();
          });
        }
      );
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);
      
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email address. Please check your email or create a new account.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        default:
          errorMessage = 'Failed to send password reset email. Please try again.';
      }
      
      _showCustomDialog("Password Reset Failed", errorMessage, isError: true);
    } catch (e) {
      setState(() => isLoading = false);
      _showCustomDialog(
        "Error", 
        "Something went wrong. Please check your internet connection and try again.", 
        isError: true
      );
    }
  }

  // Custom themed dialog
  void _showCustomDialog(String title, String message, {required bool isError, VoidCallback? onClose}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isError
                  ? [Colors.red.shade50, Colors.red.shade100]
                  : [Colors.green.shade50, Colors.green.shade100],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isError ? Colors.red : Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isError ? Colors.red.shade800 : Colors.green.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: isError ? Colors.red.shade700 : Colors.green.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isError
                        ? [Colors.red, Colors.red.shade700]
                        : [Colors.green, Colors.green.shade700],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (onClose != null) onClose();
                  },
                  child: Text(
                    'Got it!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        // Custom cursor color
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.red,
          selectionColor: Colors.red.withOpacity(0.3),
          selectionHandleColor: Colors.red,
        ),
        // Custom checkbox theme
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return null;
            }
            if (states.contains(MaterialState.selected)) {
              return Colors.red;
            }
            return null;
          }),
          checkColor: MaterialStateProperty.all(Colors.white),
        ),
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/background.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: MediaQuery.of(context).size.height * 0.25,
                right: MediaQuery.of(context).size.width * 0.25,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6AE2D).withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.25,
                left: MediaQuery.of(context).size.width * 0.33,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE94F37).withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Main content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                          image: const DecorationImage(
                            image: NetworkImage(
                              "https://uploadthingy.s3.us-west-1.amazonaws.com/hcFrRBDuLq3kSNzxKBMRw8/icon.jpg",
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        "Aaj Kya Pakayen?",
                        style: TextStyle(
                          fontFamily: "serif",
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Your personal chef that exactly knows what you are craving today",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // ===== Auth Card =====
                      Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tabs
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => isLogin = true);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isLogin ? Colors.red : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                      child: Center(
                                        child: Text(
                                          "Login",
                                          style: TextStyle(
                                            color: isLogin
                                                ? Colors.white
                                                : Colors.black54,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => isLogin = false);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: !isLogin ? Colors.red : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                      child: Center(
                                        child: Text(
                                          "Sign Up",
                                          style: TextStyle(
                                            color: !isLogin
                                                ? Colors.white
                                                : Colors.black54,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ===== Login Form =====
                            if (isLogin) ...[
                              const Text(
                                "Welcome Back!",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Login to discover delicious recipes\ntailored just for you",
                                textAlign: TextAlign.center,
                                style:
                                TextStyle(color: Colors.black54, fontSize: 14),
                              ),
                              const SizedBox(height: 20),

                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.email_outlined,
                                      color: Colors.red),
                                  hintText: "Your email address",
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              TextField(
                                controller: _passwordController,
                                obscureText: !showPassword,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.key_outlined,
                                      color: Colors.red),
                                  suffixIcon: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        showPassword = !showPassword;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 14, right: 8),
                                      child: Text(
                                        showPassword ? "Hide" : "Show",
                                        style: const TextStyle(
                                            color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                  hintText: "Your password",
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Checkbox(
                                    value: rememberMe,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        rememberMe = value ?? false;
                                      });
                                    },
                                  ),
                                  const Text("Remember me"),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: isLoading ? null : _forgotPassword,
                                    child: const Text(
                                      "Forgot password?",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  )
                                ],
                              ),

                              const SizedBox(height: 12),

                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.red, Colors.redAccent],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextButton(
                                  onPressed: isLoading ? null : _login,
                                  child: isLoading
                                      ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : const Text(
                                    "Login →",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ),
                            ],

                            // ===== Sign Up Form =====
                            if (!isLogin) ...[
                              const Text(
                                "Join the flavour club!",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Create an account to start your culinary journey",
                                textAlign: TextAlign.center,
                                style:
                                TextStyle(color: Colors.black54, fontSize: 14),
                              ),
                              const SizedBox(height: 20),

                              TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.person, color: Colors.red),
                                  hintText: "What should we call you?",
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.email_sharp, color: Colors.red),
                                  hintText: "Your email address",
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              TextField(
                                controller: _passwordController,
                                obscureText: !showPassword,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.key, color: Colors.red),
                                  suffixIcon: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        showPassword = !showPassword;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 14, right: 8),
                                      child: Text(
                                        showPassword ? "Hide" : "Show",
                                        style: const TextStyle(
                                            color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                  hintText: "Password (min 6 characters)",
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.red, Colors.redAccent],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextButton(
                                  onPressed: isLoading ? null : _signup,
                                  child: isLoading
                                      ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : const Text(
                                    "Create Account →",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              GestureDetector(
                                onTap: () {
                                  setState(() => isLogin = true);
                                },
                                child: const Text(
                                  "Already cooking with us? Login Instead",
                                  style: TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              )
                            ]
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}