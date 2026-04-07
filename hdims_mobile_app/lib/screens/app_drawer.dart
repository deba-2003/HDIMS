import 'package:flutter/material.dart';
import 'login_screen.dart'; 
import 'patient_registration_screen.dart'; // Import the new screen
import 'patient_list_screen.dart'; // Import the new screen

class AppDrawer extends StatelessWidget {
  final String userName;
  final String userRole;
  final String? facilityId;
  final String? district; 
  final String? state; // Added this! It's optional (?) because Super Admins don't have one

  const AppDrawer({
    super.key,
    required this.userName,
    required this.userRole,
    this.facilityId,
    this.district, // Add this
    this.state,    // Add this 
  });

  void _handleLogout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false, 
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero, 
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              userName, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
            ),
            accountEmail: Text(userRole),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 24, color: Colors.blueAccent),
              ),
            ),
            decoration: const BoxDecoration(
              color: Colors.blueGrey, 
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Aggregate Data Entry'),
            onTap: () {
              Navigator.pop(context); // Just closes the drawer to stay on the current screen
            },
          ),
          
          // --- NEW: Conditionally show these ONLY for Facility Admins ---
          // --- Conditionally show REGISTER button ONLY for Facility Admins ---
          if (userRole == 'Facility' && facilityId != null) 
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.teal),
              title: const Text('Register Patient'),
              onTap: () {
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => PatientRegistrationScreen(
                      facilityId: facilityId!,
                      facilityName: userName,
                      district: district ?? 'khurda', // Pass the district
                      state: state ?? 'Odisha', // Pass the state
                      // Note: To make this perfect, you should also pass the district from the Facility screen here so it saves to the DB!
                    ),
                ));
              },
            ),

          // --- Show HISTORY button for EVERYONE ---
          ListTile(
            leading: const Icon(Icons.history, color: Colors.teal),
            title: const Text('Patient Database'), // Renamed so it makes sense for Admins
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => PatientListScreen(
                    role: userRole,
                    facilityId: facilityId,
                    district: userRole == 'District Admin' ? userName : null, // Assuming userName holds the district for District Admins
                  ),
              ));
            },
          ),
          // -----------------------------------------------------------

          const Divider(), 
          
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}