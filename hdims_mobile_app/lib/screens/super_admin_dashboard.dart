import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'api_constants.dart';
import 'app_drawer.dart'; // Adjust path if needed
import 'pdf_service.dart';

class SuperAdminDashboard extends StatefulWidget {
  // 2. Add these two variables
  final String userName; 
  final String userRole;

  const SuperAdminDashboard({
    super.key,
    required this.userName,  // 3. Require them in the constructor
    required this.userRole,
  });

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  bool _isLoading = true;
  List<dynamic> _chartData = [];

  // ⚠️ Update this IP address!
  // final String dashboardUrl = 'http://192.168.29.40:3000/api/dashboard/state-summary';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.stateSummary), // Uses the central URL!
        headers: {
          "ngrok-skip-browser-warning": "true", // Crucial for Ngrok!
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
        title: const Text('Statewide Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Report',
            onPressed: () {
              if (_chartData.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No data available to export")));
                return;
              }
              
              // We trigger the PDF generation
              PdfService.generateReport(
                title: "Statewide Health Performance Report",
                chartData: _chartData,
                patientData: [], // We can fetch global patients later!
              );
            },
          ),
        ],
      ),
      drawer: AppDrawer(
        userName: widget.userName, 
        userRole: widget.userRole,
      ),
      body: _isLoading 
// ... the rest of your code stays exactly the same
        ? const Center(child: CircularProgressIndicator())
        : _chartData.isEmpty 
          ? const Center(child: Text("No performance data reported yet."))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Scheme Performance (Statewide)',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Blue: Target Population | Green: Beneficiaries Reached',
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
                  // The Bar Chart
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxYValue(), // Dynamically scale the chart
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            // Note: If you are using an older version of fl_chart, use `tooltipBgColor:` instead of `getTooltipColor:`
                            getTooltipColor: (group) => Colors.blueGrey.shade900,
                            tooltipPadding: const EdgeInsets.all(8),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              // Grab the scheme name
                              String schemeName = _chartData[group.x.toInt()]['_id'] ?? 'Unknown';
                              // Figure out if they tapped the Target (0) or Reached (1) bar
                              String category = rodIndex == 0 ? 'Target' : 'Reached';
                              
                              return BarTooltipItem(
                                '$schemeName\n',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: '$category: ${rod.toY.toInt()}',
                                    style: TextStyle(
                                      color: rodIndex == 0 ? Colors.lightBlueAccent : Colors.lightGreenAccent,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                // Shorten the scheme names to fit on the screen
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

  // Helper function to figure out how tall the chart should be
  double _getMaxYValue() {
    double max = 0;
    for (var item in _chartData) {
      if (item['totalTarget'] > max) max = item['totalTarget'].toDouble();
    }
    return max * 1.2; // Add 20% padding to the top
  }

  // Helper function to map our JSON data into Fl_Chart format
  List<BarChartGroupData> _generateBarGroups() {
    List<BarChartGroupData> groups = [];
    for (int i = 0; i < _chartData.length; i++) {
      final item = _chartData[i];
      groups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 4, // Adds a tiny gap between the two bars
          barRods: [
            BarChartRodData(
              toY: (item['totalTarget'] ?? 0).toDouble(), 
              width: 16,
              // Round the top corners
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              // Apply a blue gradient
              gradient: const LinearGradient(
                colors: [Colors.lightBlueAccent, Colors.blue],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            BarChartRodData(
              toY: (item['totalReached'] ?? 0).toDouble(), 
              width: 16,
              // Round the top corners
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              // Apply a green gradient
              gradient: const LinearGradient(
                colors: [Colors.lightGreenAccent, Colors.green],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }
    return groups;
  }
}