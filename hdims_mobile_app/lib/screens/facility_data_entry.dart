import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_constants.dart'; // adjust the path if you put it in a subfolder';
import 'app_drawer.dart'; // Adjust the path if you put it in a folder

class FacilityDataEntryScreen extends StatefulWidget {
  final String facilityId;
  final String facilityName;
  final String subDistrict;
  final String district;
  final String state;

  const FacilityDataEntryScreen({
    super.key, 
    required this.facilityId,
    required this.facilityName,
    required this.subDistrict,
    required this.district,
    required this.state,
  });

  @override
  State<FacilityDataEntryScreen> createState() => _FacilityDataEntryScreenState();
}

class _FacilityDataEntryScreenState extends State<FacilityDataEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers to grab the numbers from the text fields
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _beneficiariesController = TextEditingController();

  String _selectedScheme = 'Maternal Health Programme';
  final List<String> _schemes = [
    'Maternal Health Programme', 
    'Immunization Drive', 
    'Malaria Control',
    'Tuberculosis Eradication'
  ];

  bool _isLoading = false;

  // ⚠️ IMPORTANT: Change this to your computer's actual Wi-Fi IP address!
  // final String submitDataUrl = 'https://unceremonial-clemente-flauntily.ngrok-free.dev /api/data-entry'; 

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if the form is empty or invalid
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
  Uri.parse(ApiConstants.dataEntry),
  headers: {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true', // Add this line!
  },
  body: jsonEncode({
          // Now pulling dynamically from the logged-in user!
          'facilityId': widget.facilityId, 
          'facilityName': widget.facilityName,
          'subDistrict': widget.subDistrict,
          'district': widget.district,
          'state': widget.state,
          'schemeName': _selectedScheme,
          'targetPopulation': int.parse(_targetController.text),
          'beneficiariesReached': int.parse(_beneficiariesController.text),
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _showMessage('Success: Data recorded in the central database!');
        
        // Clear the form so they can enter the next scheme
        _targetController.clear();
        _beneficiariesController.clear();
      } else {
        _showMessage('Error: ${responseData['message']}');
      }
    } catch (e) {
      _showMessage('Failed to connect to the server.');
      debugPrint(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    _beneficiariesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.facilityName} - Data Entry'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(
        userName: widget.facilityName, 
        userRole: 'Facility',
        facilityId: widget.facilityId,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Enter Health Scheme Performance',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              DropdownButtonFormField<String>(
                value: _selectedScheme,
                decoration: const InputDecoration(
                  labelText: 'Select Health Programme',
                  border: OutlineInputBorder(),
                ),
                items: _schemes.map((String scheme) {
                  return DropdownMenuItem<String>(
                    value: scheme,
                    child: Text(scheme),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedScheme = newValue!),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Population',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter a number' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _beneficiariesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Beneficiaries Reached',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.check_circle),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter a number' : null,
              ),
              const SizedBox(height: 30),

              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Submit Data', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}