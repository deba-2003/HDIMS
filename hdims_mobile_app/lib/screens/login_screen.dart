import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'registration_screen.dart';
import 'dashboard_screen.dart'; // Added the dashboard import
import 'api_constants.dart'; // adjust the path if you put it in a subfolder';

import 'facility_data_entry.dart';
import 'super_admin_dashboard.dart';
import 'district_admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Change this line in both files:
final List<String> _roles = ['Facility', 'District Admin', 'Super Admin'];
String _selectedRole = 'Facility';
  bool _isLoading = false;

  // final String backendUrl = 'https://ngrok.com/r/ai/api/login';

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter both email and password');
      return;
    }
    

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login), // Use the constant from api_constants.dart
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', // Add this exact line!
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': _selectedRole,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showMessage('Success: ${responseData['message']}');
        
        if (mounted) {
          final String userRole = responseData['user']['role'];
          final String userName = responseData['user']['name'];

          // THIS IS THE MISSING LINE: We must declare the variable first!
          Widget nextScreen;

          // ROUTING LOGIC: Decide which screen to show based on the role
          // ROUTING LOGIC: Decide which screen to show based on the role
          if (userRole == 'Facility') {
            nextScreen = FacilityDataEntryScreen(
              facilityId: responseData['user']['_id'] ?? 'Unknown ID',
              facilityName: userName,
              subDistrict: responseData['user']['subDistrict'] ?? 'Unknown Sub-District',
              district: responseData['user']['district'] ?? 'Unknown District',
              state: responseData['user']['state'] ?? 'Odisha',
            );
          } else if (userRole == 'Super Admin') {
            nextScreen =  SuperAdminDashboard(
              userName: userName, 
              userRole: userRole,
            );
          } else if (userRole == 'District Admin') {
            // Grab the district from the user object, fallback to Khordha if missing
            final String userDistrict = responseData['user']['district'] ?? 'Khordha';
            nextScreen = DistrictAdminDashboard(
              districtName: userDistrict, 
              userName: userName, 
              userRole: userRole,
            );
          } else {
            nextScreen = DashboardScreen(role: userRole, name: userName);
          }

          // Push to the selected screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => nextScreen),
          );
        }
      } else {
        _showMessage('Error: ${responseData['message']}');
      
      }
    } catch (e) {
      _showMessage('Failed to connect to the server. Check your network/IP.');
      // FIX 2: Changed print() to debugPrint()
      debugPrint(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.health_and_safety,
                size: 80,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to HDIMS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 40),
              
              DropdownButtonFormField<String>(
                // FIX 3: Changed 'value' to 'initialValue'
                initialValue: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Select Role',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                items: _roles.map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRole = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistrationScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Don't have an account? Sign Up",
                  style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}