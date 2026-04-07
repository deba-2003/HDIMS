import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'api_constants.dart';
import 'app_drawer.dart'; // Adjust path if needed

class DistrictAdminDashboard extends StatefulWidget {
  final String districtName;
  final String userName; // 2. Add this
  final String userRole; // 3. Add this
  
  const DistrictAdminDashboard({
    super.key, 
    required this.districtName,
    required this.userName, // 4. Require it
    required this.userRole, // 5. Require it
  });

  @override
  State<DistrictAdminDashboard> createState() => _DistrictAdminDashboardState();
}

class _DistrictAdminDashboardState extends State<DistrictAdminDashboard> {
 bool _isLoading = true;
 List<dynamic> _chartData = [];

 @override
 void initState() {
  super.initState();
  _fetchDistrictData();
 }

 Future<void> _fetchDistrictData() async {
  // ⚠️ Update this IP address!
  // Notice how we inject widget.districtName into the URL
  // final String url = 'https://unceremonial-clemente-flauntily.ngrok-free.dev /api/dashboard/district-summary/${widget.districtName}';
  
  try {
   final response = await http.get(
  Uri.parse(ApiConstants.districtSummary(widget.districtName)),
  headers: {
    "ngrok-skip-browser-warning": "true", // This skips the HTML warning page
  },
);
   if (response.statusCode == 200) {
    setState(() {
     _chartData = jsonDecode(response.body);
     _isLoading = false;
    });
   }
  } catch (e) {
   debugPrint("Error fetching data: $e");
   setState(() => _isLoading = false);
  }
 }

 @override
 Widget build(BuildContext context) {
  return Scaffold(
   appBar: AppBar(
    title: Text('${widget.districtName} District Dashboard'),
    backgroundColor: Colors.blueGrey,
         foregroundColor: Colors.white,
   ),
   drawer: AppDrawer(
        userName: widget.userName, 
        userRole: widget.userRole,
      ),
   body: _isLoading 
    ? const Center(child: CircularProgressIndicator())
    : _chartData.isEmpty 
     ? Center(child: Text("No performance data reported yet for ${widget.districtName}."))
     : Padding(
       padding: const EdgeInsets.all(16.0),
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
         Text(
          'Scheme Performance (${widget.districtName})',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
         ),
         const SizedBox(height: 10),
         const Text(
          'Blue: Target Population | Green: Beneficiaries Reached',
          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
         ),
         const SizedBox(height: 30),
         
         Expanded(
          child: BarChart(
           BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _getMaxYValue(),
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
             show: true,
             bottomTitles: AxisTitles(
              sideTitles: SideTitles(
               showTitles: true,
               getTitlesWidget: (double value, TitleMeta meta) {
                String title = _chartData[value.toInt()]['_id'];
                if (title.contains('Maternal')) return const Text('Maternal', style: TextStyle(fontSize: 10));
                if (title.contains('Immunization')) return const Text('Immuniz.', style: TextStyle(fontSize: 10));
                if (title.contains('Malaria')) return const Text('Malaria', style: TextStyle(fontSize: 10));
                if (title.contains('Tuberculosis')) return const Text('TB', style: TextStyle(fontSize: 10));
                return Text(title.substring(0, 5), style: const TextStyle(fontSize: 10));
               },
               reservedSize: 30,
              ),
             ),
             leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
             ),
             topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
             rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: _generateBarGroups(),
           ),
          ),
         ),
        ],
       ),
      ),
  );
 }

 double _getMaxYValue() {
  double max = 0;
  for (var item in _chartData) {
   if (item['totalTarget'] > max) max = item['totalTarget'].toDouble();
  }
  return max == 0 ? 100 : max * 1.2; 
 }

 List<BarChartGroupData> _generateBarGroups() {
  List<BarChartGroupData> groups = [];
  for (int i = 0; i < _chartData.length; i++) {
   final item = _chartData[i];
   groups.add(
    BarChartGroupData(
     x: i,
     barRods: [
      BarChartRodData(toY: item['totalTarget'].toDouble(), color: Colors.blue, width: 15),
      BarChartRodData(toY: item['totalReached'].toDouble(), color: Colors.green, width: 15),
     ],
    ),
   );
  }
  return groups;
 }
}  