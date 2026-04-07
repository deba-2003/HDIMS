import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'api_constants.dart'; // Adjust path if needed
import 'app_drawer.dart'; // Adjust path if needed

class DashboardScreen extends StatefulWidget {
  final String role;
  final String name;

  const DashboardScreen({
    super.key, 
    required this.role, 
    required this.name,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<dynamic> _chartData = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final response = await http.get(
        // Passing the user's name/jurisdiction to the backend
        Uri.parse(ApiConstants.genericSummary(widget.name)), 
        headers: {
          "ngrok-skip-browser-warning": "true", // Crucial for Ngrok!
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _chartData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        debugPrint("Server returned an error: ${response.statusCode}");
        setState(() => _isLoading = false);
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
        title: Text('${widget.role} Dashboard'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(userName: widget.name, userRole: widget.role),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _chartData.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance, size: 80, color: Colors.blueGrey),
                  const SizedBox(height: 16),
                  Text("Welcome, ${widget.name}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("No performance data reported yet.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Performance Data (${widget.name})',
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
                  
                  // The Bar Chart
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxYValue(), 
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
                                String title = _chartData[value.toInt()]['_id'] ?? 'Unknown';
                                if (title.contains('Maternal')) return const Text('Maternal', style: TextStyle(fontSize: 10));
                                if (title.contains('Immunization')) return const Text('Immuniz.', style: TextStyle(fontSize: 10));
                                if (title.contains('Malaria')) return const Text('Malaria', style: TextStyle(fontSize: 10));
                                if (title.contains('Tuberculosis')) return const Text('TB', style: TextStyle(fontSize: 10));
                                return Text(title.substring(0, title.length > 5 ? 5 : title.length), style: const TextStyle(fontSize: 10));
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
      if ((item['totalTarget'] ?? 0) > max) max = item['totalTarget'].toDouble();
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