import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'home_page.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );

      if (!mounted) return;

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to register. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _registerWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signInWithGoogle();
      if (!mounted) return;

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to register with Google. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildRegistrationForm(),
                        const SizedBox(height: 16),
                        _buildRegisterButton(),
                        const SizedBox(height: 24),
                        _buildDivider(),
                        const SizedBox(height: 24),
                        _buildSocialLogin(),
                        const SizedBox(height: 24),
                        _buildLoginPrompt(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Text(
              'Back to login',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.person_add_outlined,
            size: 40,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign up to get started with managing your finances',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            color: Colors.grey[600],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                  child: Icon(Icons.close, color: Colors.red[700], size: 20),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormField(
            label: 'Full Name',
            hintText: 'John Doe',
            controller: _nameController,
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildFormField(
            label: 'Email',
            hintText: 'your.email@example.com',
            controller: _emailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildFormField(
            label: 'Password',
            hintText: '••••••••',
            controller: _passwordController,
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            toggleObscure: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildFormField(
            label: 'Confirm Password',
            hintText: '••••••••',
            controller: _confirmPasswordController,
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            toggleObscure: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required IconData prefixIcon,
    Function()? toggleObscure,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            fontFamily: 'Poppins',
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
            suffixIcon: toggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey[600],
                    ),
                    onPressed: toggleObscure,
                  )
                : null,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            fillColor: Colors.grey[100],
            filled: true,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        child: const Text('Register'),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey[400],
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or sign up with',
            style: TextStyle(
              color: Colors.grey[600],
              fontFamily: 'Poppins',
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey[400],
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLogin() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _registerWithGoogle,
        icon: const Icon(Icons.g_mobiledata, size: 24),
        label: const Text(
          'Continue with Google',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          child: Text(
            'Sign In',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// import 'package:flutter/material.dart';
// import '../services/auth_service.dart';
//
// class SignUpScreen extends StatefulWidget {
//   const SignUpScreen({super.key});
//
//   @override
//   _SignUpScreenState createState() => _SignUpScreenState();
// }
//
// class _SignUpScreenState extends State<SignUpScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   final _authService = AuthService();
//   bool _isLoading = false;
//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//   String? _error;
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _signUp() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//
//     try {
//       await _authService.registerWithEmailAndPassword(
//         _emailController.text.trim(),
//         _passwordController.text,
//         _nameController.text.trim(),
//       );
//       if (!mounted) return;
//       Navigator.pushReplacementNamed(context, '/home');
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//       });
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   // Logo and Title
//                   Icon(
//                     Icons.account_balance_wallet,
//                     size: 80,
//                     color: Theme.of(context).primaryColor,
//                   ),
//                   const SizedBox(height: 24),
//                   Text(
//                     'Create Account',
//                     style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Join us to start managing your finances',
//                     style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                           color: Colors.grey[600],
//                         ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 48),
//
//                   // Name Field
//                   TextFormField(
//                     controller: _nameController,
//                     decoration: InputDecoration(
//                       labelText: 'Full Name',
//                       hintText: 'Enter your full name',
//                       prefixIcon: const Icon(Icons.person_outline),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(
//                           color: Colors.grey[300]!,
//                         ),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(
//                           color: Theme.of(context).primaryColor,
//                           width: 2,
//                         ),
//                       ),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your name';
//                       }
//                       if (value.length < 2) {
//                         return 'Name must be at least 2 characters';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16),
//
//                   // Email Field
//                   TextFormField(
//                     controller: _emailController,
//                     keyboardType: TextInputType.emailAddress,
//                     decoration: InputDecoration(
//                       labelText: 'Email',
//                       hintText: 'Enter your email',
//                       prefixIcon: const Icon(Icons.email_outlined),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(
//                           color: Colors.grey[300]!,
//                         ),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(
//                           color: Theme.of(context).primaryColor,
//                           width: 2,
//                         ),
//                       ),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your email';
//                       }
//                       if (!value.contains('@') || !value.contains('.')) {
//                         return 'Please enter a valid email';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16),
//
//                   // Password Field
//                   TextFormField(
//                     controller: _passwordController,
//                     obscureText: _obscurePassword,
//                     decoration: InputDecoration(
//                       labelText: 'Password',
//                       hintText: 'Enter your password',
//                       prefixIcon: const Icon(Icons.lock_outline),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _obscurePassword
//                               ? Icons.visibility_outlined
//                               : Icons.visibility_off_outlined,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _obscurePassword = !_obscurePassword;
//                           });
//                         },
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(
//                           color: Colors.grey[300]!,
//                         ),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(
//                           color: Theme.of(context).primaryColor,
//                           width: 2,
//                         ),
//                       ),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your password';
//                       }
//                       if (value.length < 6) {
//                         return 'Password must be at least 6 characters';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16),
//
//                   // Confirm Password Field
//                   TextFormField(
//                     controller: _confirmPasswordController,
//                     obscureText: _obscureConfirmPassword,
//                     decoration: InputDecoration(
//                       labelText: 'Confirm Password',
//                       hintText: 'Confirm your password',
//                       prefixIcon: const Icon(Icons.lock_outline),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _obscureConfirmPassword
//                               ? Icons.visibility_outlined
//                               : Icons.visibility_off_outlined,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _obscureConfirmPassword = !_obscureConfirmPassword;
//                           });
//                         },
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(
//                           color: Colors.grey[300]!,
//                         ),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(
//                           color: Theme.of(context).primaryColor,
//                           width: 2,
//                         ),
//                       ),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please confirm your password';
//                       }
//                       if (value != _passwordController.text) {
//                         return 'Passwords do not match';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 24),
//
//                   // Sign Up Button
//                   ElevatedButton(
//                     onPressed: _isLoading ? null : _signUp,
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: _isLoading
//                         ? const SizedBox(
//                             height: 20,
//                             width: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor:
//                                   AlwaysStoppedAnimation<Color>(Colors.white),
//                             ),
//                           )
//                         : const Text(
//                             'Sign Up',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                   ),
//                   const SizedBox(height: 16),
//
//                   // Sign In Option
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'Already have an account?',
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.pushReplacementNamed(context, '/login');
//                         },
//                         child: const Text('Sign In'),
//                       ),
//                     ],
//                   ),
//
//                   if (_error != null) ...[
//                     const SizedBox(height: 16),
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.red[50],
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color: Colors.red[200]!,
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.error_outline,
//                             color: Colors.red[700],
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Text(
//                               _error!,
//                               style: TextStyle(
//                                 color: Colors.red[700],
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
