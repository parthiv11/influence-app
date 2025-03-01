import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isPhoneLogin = false; // Default to email login
  bool isLoading = false;
  bool obscurePassword = true;
  bool isInfluencer = true; // Default to influencer mode
  String? verificationId;

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    otpController.dispose();
    super.dispose();
  }

  // Handle login with email and password
  Future<void> _loginWithEmail() async {
    setState(() => isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.signInWithEmailPassword(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
      }
    } catch (e) {
      _showErrorMessage("Login failed: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Handle registration with email and password
  Future<void> _registerWithEmail() async {
    setState(() => isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.registerWithEmailPassword(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user != null) {
        _showSuccessMessage("Registration successful!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
      }
    } catch (e) {
      _showErrorMessage("Registration failed: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Handle phone verification
  Future<void> _verifyPhone() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter phone number")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.legacyVerifyPhoneNumber(context, phone);
    } catch (e) {
      _showErrorMessage("Phone verification failed: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Verify OTP code
  Future<void> _verifyOtp(String otp) async {
    if (verificationId == null) {
      _showErrorMessage("Verification ID is missing. Please try again.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.verifyWithCode(verificationId!, otp);

      if (user != null) {
        Navigator.pop(context); // Close OTP dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
      }
    } catch (e) {
      _showErrorMessage("OTP verification failed: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Show OTP dialog
  void _showOtpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text("Enter OTP"),
            content: TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: "OTP"),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  _verifyOtp(otpController.text.trim());
                },
                child: Text("Verify"),
              ),
            ],
          ),
    );
  }

  // Show error message
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Show success message
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0E0E10), // Darker twitch background
              Color(0xFF1F1F23), // Twitch dark background
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Logo and branding
                    const Icon(
                      Icons.cast_connected,
                      size: 70,
                      color: Color(0xFF9146FF), // Twitch purple
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "InfluencerConnect",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Where brands and influencers connect",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),

                    // User type selection
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF26262C),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isInfluencer = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isInfluencer
                                            ? const Color(0xFF9146FF)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Influencer",
                                      style: TextStyle(
                                        color:
                                            isInfluencer
                                                ? Colors.white
                                                : Colors.grey,
                                        fontWeight:
                                            isInfluencer
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isInfluencer = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        !isInfluencer
                                            ? const Color(0xFF9146FF)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Brand",
                                      style: TextStyle(
                                        color:
                                            !isInfluencer
                                                ? Colors.white
                                                : Colors.grey,
                                        fontWeight:
                                            !isInfluencer
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login form card
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Login method toggle
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ChoiceChip(
                                  label: const Text('Email'),
                                  selected: !isPhoneLogin,
                                  onSelected: (selected) {
                                    setState(() {
                                      isPhoneLogin = !selected;
                                    });
                                  },
                                  selectedColor: const Color(0xFF9146FF),
                                ),
                                const SizedBox(width: 16),
                                ChoiceChip(
                                  label: const Text('Phone'),
                                  selected: isPhoneLogin,
                                  onSelected: (selected) {
                                    setState(() {
                                      isPhoneLogin = selected;
                                    });
                                  },
                                  selectedColor: const Color(0xFF9146FF),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Phone or Email Login based on toggle
                            if (isPhoneLogin)
                              _buildPhoneLoginForm()
                            else
                              _buildEmailLoginForm(),

                            // Divider
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(color: Colors.grey),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  "OR",
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Divider(color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Social login buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _buildSocialButton(
                                    icon: Icons.g_mobiledata,
                                    label: "Google",
                                    color: Colors.red,
                                    onPressed:
                                        () => authService.signInWithGoogle(
                                          context,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildSocialButton(
                                    icon: Icons.facebook,
                                    label: "Facebook",
                                    color: Colors.blue,
                                    onPressed:
                                        () => authService.signInWithFacebook(
                                          context,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Help text
                    const SizedBox(height: 24),
                    Text(
                      isInfluencer
                          ? "Join as an influencer to showcase your content and connect with brands"
                          : "Join as a brand to discover and collaborate with influencers",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF26262C),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildPhoneLoginForm() {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Column(
      children: [
        Text(
          "Enter Your Phone Number",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color:
                isInfluencer
                    ? const Color(0xFF9146FF) // Twitch purple for influencers
                    : const Color(0xFF1F69FF), // Twitch blue for brands
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: "Phone number",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.phone),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor:
                  isInfluencer
                      ? const Color(0xFF9146FF) // Twitch purple for influencers
                      : const Color(0xFF1F69FF), // Twitch blue for brands
            ),
            onPressed: isLoading ? null : () => _verifyPhone(),
            child:
                isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text("Send OTP", style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailLoginForm() {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Column(
      children: [
        Text(
          isInfluencer ? "Influencer Login" : "Brand Login",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color:
                isInfluencer
                    ? const Color(0xFF9146FF) // Twitch purple for influencers
                    : const Color(0xFF1F69FF), // Twitch blue for brands
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: "Email address",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            hintText: "Password",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  obscurePassword = !obscurePassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                _showSignUpDialog(context);
              },
              child: const Text("Sign Up"),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
            TextButton(
              onPressed: () {
                // Forgot password functionality
                if (emailController.text.trim().isNotEmpty) {
                  authService.sendPasswordResetEmail(
                    context,
                    emailController.text.trim(),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Enter your email address first"),
                    ),
                  );
                }
              },
              child: const Text("Forgot Password?"),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isInfluencer
                      ? const Color(0xFF9146FF) // Twitch purple for influencers
                      : const Color(0xFF1F69FF), // Twitch blue for brands
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: isLoading ? null : () => _loginWithEmail(),
            child:
                isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text("Login", style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  void _showSignUpDialog(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  backgroundColor: const Color(0xFF18181B),
                  title: Text(
                    isInfluencer ? "Join as an Influencer" : "Join as a Brand",
                    style: const TextStyle(color: Colors.white),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            hintText: "Enter your email",
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            hintText: "Create a password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: "Confirm Password",
                            hintText: "Confirm your password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureConfirmPassword =
                                      !obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                      style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final email = emailController.text.trim();
                        final password = passwordController.text;
                        final confirmPassword = confirmPasswordController.text;

                        if (email.isEmpty ||
                            password.isEmpty ||
                            confirmPassword.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("All fields are required"),
                            ),
                          );
                          return;
                        }

                        if (password != confirmPassword) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Passwords do not match"),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context); // Close dialog

                        _registerWithEmail();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isInfluencer
                                ? const Color(0xFF9146FF) // Twitch purple
                                : const Color(0xFF1F69FF), // Twitch blue
                      ),
                      child: const Text("Sign Up"),
                    ),
                  ],
                ),
          ),
    );
  }
}
