import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_constants.dart';

class PatientListScreen extends StatefulWidget {
  final String role;
  final String? facilityId;
  final String? district;

  const PatientListScreen({
    super.key, 
    required this.role, 
    this.facilityId, 
    this.district
  });

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  bool _isLoading = true;
  List<dynamic> _patients = [];

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      // Use our new smart URL builder!
      final url = ApiConstants.getPatientsUrl(
        widget.role, 
        facilityId: widget.facilityId, 
        district: widget.district
      );

      final response = await http.get(Uri.parse(url), headers: {'ngrok-skip-browser-warning': 'true'});

      if (response.statusCode == 200) {
        setState(() {
          _patients = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
  
  // ... Keep your existing @override Widget build(BuildContext context) exactly the same!

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient History'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _patients.isEmpty
              ? const Center(child: Text('No patients registered yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _patients.length,
                  itemBuilder: (context, index) {
                    final patient = _patients[index];
                    // Format the date to be readable
                    final date = DateTime.parse(patient['treatmentDate']).toLocal();
                    final formattedDate = "${date.day}/${date.month}/${date.year}";

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Icon(
                            patient['gender'] == 'Female' ? Icons.woman : Icons.man,
                            color: Colors.teal.shade800,
                          ),
                        ),
                        title: Text(patient['patientName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${patient['healthScheme']}\nAge: ${patient['age']} | Date: $formattedDate'),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // You can add a dialog here later to show full medical notes!
                        },
                      ),
                    );
                  },
                ),
    );
  }
}