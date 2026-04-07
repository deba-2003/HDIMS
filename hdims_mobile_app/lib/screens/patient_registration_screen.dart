import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_constants.dart';

class PatientRegistrationScreen extends StatefulWidget {
  final String facilityId;
  final String facilityName;

  const PatientRegistrationScreen({
    super.key,
    required this.facilityId,
    required this.facilityName,
  });

  @override
  State<PatientRegistrationScreen> createState() => _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _diagnosisController = TextEditingController();

  String _selectedGender = 'Male';
  final List<String> _genders = ['Male', 'Female', 'Other'];

  String _selectedScheme = 'Maternal Health Programme';
  final List<String> _schemes = [
    'Maternal Health Programme',
    'Immunization Drive',
    'Malaria Control',
    'Tuberculosis Eradication'
  ];

  bool _isLoading = false;

  Future<void> _submitPatient() async {
    if (_nameController.text.isEmpty || _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name and age.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.addPatient),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'facilityId': widget.facilityId,
          'facilityName': widget.facilityName,
          'patientName': _nameController.text.trim(),
          'age': int.parse(_ageController.text.trim()),
          'gender': _selectedGender,
          'contactNumber': _contactController.text.trim(),
          'healthScheme': _selectedScheme,
          'diagnosis': _diagnosisController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient Registered Successfully!')),
        );
        Navigator.pop(context); // Go back after successful registration
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${jsonDecode(response.body)['message']}')),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Failed to save patient.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Patient'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Patient Full Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
              items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => setState(() => _selectedGender = val!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedScheme,
              decoration: const InputDecoration(labelText: 'Health Scheme', border: OutlineInputBorder()),
              items: _schemes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => _selectedScheme = val!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _diagnosisController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Medical Notes / Diagnosis', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _submitPatient,
                    child: const Text('Save Patient', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
  }
}