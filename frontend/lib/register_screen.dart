// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'login_screen.dart'; // Import your login screen

// class RegisterScreen extends StatefulWidget {
//   @override
//   _RegisterScreenState createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final _formKey = GlobalKey<FormState>();

//   final _usernameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();

//   bool _isLoading = false;
//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;

//   Future<void> registerUser() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() => _isLoading = true);

//       try {
//         final response = await http.post(
//           Uri.parse('https://your-backend-domain.com/api/register/'), // ← Change this URL
//           headers: {'Content-Type': 'application/json'},
//           body: jsonEncode({
//             'username': _usernameController.text.trim(),
//             'email': _emailController.text.trim(),
//             'password': _passwordController.text,
//           }),
//         );

//         if (response.statusCode == 201) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Registration Successful! Please login.'),
//               backgroundColor: Colors.green,
//             ),
//           );
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => LoginScreen()),
//           );
//         } else {
//           final error = jsonDecode(response.body);
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(error['detail'] ?? 'Registration failed!'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Network error. Please try again.')),
//         );
//       } finally {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Create Account"),
//         backgroundColor: Colors.teal,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "Join AirGuard Dar",
//                 style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//               ),
//               const Text(
//                 "Get personalized air quality alerts and recommendations",
//                 style: TextStyle(fontSize: 16, color: Colors.grey),
//               ),
//               const SizedBox(height: 32),

//               TextFormField(
//                 controller: _usernameController,
//                 decoration: const InputDecoration(
//                   labelText: "Username",
//                   border: OutlineInputBorder(),
//                   prefixIcon: Icon(Icons.person),
//                 ),
//                 validator: (value) =>
//                     value!.isEmpty ? "Username is required" : null,
//               ),
//               const SizedBox(height: 16),

//               TextFormField(
//                 controller: _emailController,
//                 keyboardType: TextInputType.emailAddress,
//                 decoration: const InputDecoration(
//                   labelText: "Email Address",
//                   border: OutlineInputBorder(),
//                   prefixIcon: Icon(Icons.email),
//                 ),
//                 validator: (value) {
//                   if (value!.isEmpty) return "Email is required";
//                   if (!value.contains("@")) return "Enter a valid email";
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),

//               TextFormField(
//                 controller: _passwordController,
//                 obscureText: _obscurePassword,
//                 decoration: InputDecoration(
//                   labelText: "Password",
//                   border: const OutlineInputBorder(),
//                   prefixIcon: const Icon(Icons.lock),
//                   suffixIcon: IconButton(
//                     icon: Icon(_obscurePassword
//                         ? Icons.visibility_off
//                         : Icons.visibility),
//                     onPressed: () =>
//                         setState(() => _obscurePassword = !_obscurePassword),
//                   ),
//                 ),
//                 validator: (value) =>
//                     value!.length < 6 ? "Password must be at least 6 characters" : null,
//               ),
//               const SizedBox(height: 16),

//               TextFormField(
//                 controller: _confirmPasswordController,
//                 obscureText: _obscureConfirmPassword,
//                 decoration: InputDecoration(
//                   labelText: "Confirm Password",
//                   border: const OutlineInputBorder(),
//                   prefixIcon: const Icon(Icons.lock),
//                   suffixIcon: IconButton(
//                     icon: Icon(_obscureConfirmPassword
//                         ? Icons.visibility_off
//                         : Icons.visibility),
//                     onPressed: () => setState(() =>
//                         _obscureConfirmPassword = !_obscureConfirmPassword),
//                   ),
//                 ),
//                 validator: (value) {
//                   if (value != _passwordController.text) {
//                     return "Passwords do not match";
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 32),

//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : registerUser,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.teal,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: _isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                           "Register",
//                           style: TextStyle(fontSize: 18),
//                         ),
//                 ),
//               ),

//               const SizedBox(height: 16),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Text("Already have an account?"),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(builder: (context) => LoginScreen()),
//                       );
//                     },
//                     child: const Text("Login"),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }r
// }