import 'package:flutter/material.dart';

class AuthGate extends StatefulWidget {
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool showPassword = false;
  bool isLogin = true; // Toggle state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                                          color: Colors.black54, fontSize: 12),
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
                                Checkbox(value: false, onChanged: (_) {}),
                                const Text("Remember me"),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {},
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
                                onPressed: () {},
                                child: const Text(
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

                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.red, Colors.redAccent],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextButton(
                                onPressed: () {},
                                child: const Text(
                                  "Continue →",
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
                                  decoration: TextDecoration.underline,
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
    );
  }
}
