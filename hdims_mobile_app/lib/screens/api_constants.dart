class ApiConstants {
  // Update THIS string whenever you restart Ngrok!
  static const String baseUrl = 'https://unceremonial-clemente-flauntily.ngrok-free.dev/api'; 
  
  // --- Auth Endpoints ---
  static const String login = '$baseUrl/login';
  static const String register = '$baseUrl/register';
  
  // --- Aggregate Data Endpoints ---
  static const String dataEntry = '$baseUrl/data-entry';
  static const String stateSummary = '$baseUrl/dashboard/state-summary';
  
  static String districtSummary(String districtName) {
    return '$baseUrl/dashboard/district-summary/$districtName';
  }

  static String genericSummary(String name) {
    return '$baseUrl/dashboard/generic-summary/$name';
  }

  // --- Granular Patient Endpoints ---
  static const String addPatient = '$baseUrl/patients/add';
  
  // Dynamic URL builder based on Role!
  static String getPatientsUrl(String role, {String? facilityId, String? district}) {
    if (role == 'Super Admin') return '$baseUrl/patients/admin/all';
    if (role == 'District Admin') return '$baseUrl/patients/admin/district/$district';
    return '$baseUrl/patients/$facilityId'; // Default to Facility
  }
}