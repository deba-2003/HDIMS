import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_constants.dart'; // adjust the path if you put it in a subfolder

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _selectedRole = 'Facility';
  final List<String> _roles = ['Facility', 'District Admin', 'Super Admin'];
  
  // Location State Variables
  String _selectedState = 'Odisha';
  String _selectedDistrict = 'Khordha';
  String _selectedSubDistrict = 'Bhubaneswar';

  // Sample mapping of Districts to Sub-districts
  final Map<String, List<String>> _districtData = {
    'Khordha': ['Bhubaneswar', 'Jatani', 'Khurda', 'Balianta'],
    'Cuttack': ['Cuttack City', 'Athagarh', 'Choudwar', 'Salepur'],
    'Ganjam': ['Brahmapur', 'Chatrapur', 'Hinjilicut', 'Bhanjanagar'],
    'Sundargarh': ['Rourkela', 'Rajgangpur', 'Sundargarh Town'],
  };

  bool _isLoading = false;

  // Make sure this is your active IP address
  // final String registerUrl = 'http://192.168.29.40:3000/api/register';

  Future<void> _handleRegistration() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Please fill in all text fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.register), // Using the centralized URL!
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', // Crucial for Ngrok!
        },
        body: jsonEncode({
          'name': name, // Using the variable you declared on line 42
          'email': email, // Using the variable you declared on line 43
          'password': password, // Using the variable you declared on line 44
          'role': _selectedRole,
          'state': _selectedState,
          'district': _selectedDistrict,
          'subDistrict': _selectedSubDistrict,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _showMessage('Account Created Successfully!');
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _showMessage('Error: ${responseData['message']}');
      }
    } catch (e) {
      _showMessage('Failed to connect to the server. Check your network.');
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
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.blueAccent, 
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Join HDIMS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 30),

              // Role Dropdown
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'I am a...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.badge),
                ),
                items: _roles.map((String role) {
                  return DropdownMenuItem<String>(value: role, child: Text(role));
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedRole = newValue!),
              ),
              const SizedBox(height: 15),

              // District Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: InputDecoration(
                  labelText: 'District',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.map),
                ),
                items: _districtData.keys.map((String district) {
                  return DropdownMenuItem<String>(value: district, child: Text(district));
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedDistrict = newValue!;
                    // Automatically reset the sub-district when the district changes
                    _selectedSubDistrict = _districtData[_selectedDistrict]!.first;
                  });
                },
              ),
              const SizedBox(height: 15),

              // Sub-District Dropdown (Cascading)
              DropdownButtonFormField<String>(
                value: _selectedSubDistrict,
                decoration: InputDecoration(
                  labelText: 'Sub-District / City',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.location_city),
                ),
                items: _districtData[_selectedDistrict]!.map((String subDistrict) {
                  return DropdownMenuItem<String>(value: subDistrict, child: Text(subDistrict));
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedSubDistrict = newValue!),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Facility / Admin Name',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),

              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _handleRegistration,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: const Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}