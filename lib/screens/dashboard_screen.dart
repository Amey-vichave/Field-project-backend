import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore integration
import 'package:intl/intl.dart'; // For date parsing
import 'package:pharmcare/screens/signup_screen.dart';
import 'inventory_screen.dart';
import 'package:pharmcare/screens/medicine_alerts_screen.dart';
import 'package:pharmcare/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:pharmcare/providers/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:pharmcare/screens/restock_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isDarkMode = false;
  String selectedGraph = "Revenue"; // Toggle between Revenue & Profit
  String selectedTimeFrame = "Daily"; // Daily, Weekly, Monthly

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'PharmCare Dashboard',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        elevation: 2,
      ),
      drawer: _buildSidebarMenu(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            SizedBox(height: 20),
            _buildAnalyticsSection(),
            SizedBox(height: 20),
            _buildRevenueProfitGraph(),
            SizedBox(height: 20),
            _buildStockAlertsSection(context),
            SizedBox(height: 20),
            _buildBestSellingList(),
          ],
        ),
      ),
    );
  }

  // Sidebar Drawer
  Widget _buildSidebarMenu(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return UserAccountsDrawerHeader(
                accountName:
                    Text(userProvider.userName, style: TextStyle(fontSize: 18)),
                accountEmail: Text("example@gmail.com"),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: kIsWeb
                      ? (userProvider.profileImageBytes != null
                          ? MemoryImage(userProvider.profileImageBytes!)
                          : null)
                      : (userProvider.profileImageFile != null
                          ? FileImage(userProvider.profileImageFile!)
                          : null),
                  child: (userProvider.profileImageBytes == null &&
                          userProvider.profileImageFile == null)
                      ? Icon(Icons.person, color: Colors.green, size: 40)
                      : null,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green, Colors.teal]),
                ),
              );
            },
          ),
          _buildDrawerItem(Icons.dashboard, "Dashboard", () {
            Navigator.pop(context);
          }),
          _buildDrawerItem(Icons.inventory, "Inventory", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => InventoryScreen()));
          }),
          _buildDrawerItem(Icons.person, "Profile", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ProfileScreen()));
          }),
          _buildDrawerItem(Icons.logout, "Logout", () {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => SignupScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  // Welcome Card
  Widget _buildWelcomeCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.green.shade300,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.local_pharmacy, size: 50, color: Colors.white),
            SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome Back!",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text("Manage your pharmacy with ease.",
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Analytics Cards
  Widget _buildAnalyticsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInfoCard(
            Icons.attach_money, "Total Sales", "₹1,20,000", Colors.green),
        _buildInfoCard(Icons.show_chart, "Profit", "₹40,000", Colors.teal),
      ],
    );
  }

  // Stock Alerts Section with Firestore Integration
  Widget _buildStockAlertsSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No medicines found"));
        }

        final medicines = snapshot.data!.docs;

        // Filter medicines for alerts
        final expiredMedicines = medicines.where((medicine) {
          final expiry = medicine['expiry'];
          final now = DateTime.now();
          final parts =
              expiry.split('/'); // Split "MM/yyyy" into ["MM", "yyyy"]
          final expiryDate = DateTime(
              int.parse(parts[1]), int.parse(parts[0])); // Create DateTime
          return expiryDate.isBefore(now);
        }).toList();

        final nearExpiryMedicines = medicines.where((medicine) {
          final expiry = medicine['expiry'];
          final now = DateTime.now();
          final parts =
              expiry.split('/'); // Split "MM/yyyy" into ["MM", "yyyy"]
          final expiryDate = DateTime(
              int.parse(parts[1]), int.parse(parts[0])); // Create DateTime
          final difference = expiryDate.difference(now).inDays;
          return difference <= 30 && difference > 0; // Near expiry in 30 days
        }).toList();

        final lowStockMedicines = medicines.where((medicine) {
          final stock = medicine['stock'];
          final threshold = medicine['lowStockThreshold'] ??
              10; // Use default value if field is missing
          return stock <= threshold;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Stock Alerts",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Expired Medicines
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                MedicineAlertsScreen(initialTab: 0)),
                      );
                    },
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.red,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.cancel, color: Colors.white, size: 30),
                            SizedBox(height: 8),
                            Text("Expired",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 5),
                            Text("${expiredMedicines.length} Items",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),

                // Near Expiry Medicines
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                MedicineAlertsScreen(initialTab: 1)),
                      );
                    },
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.orange,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.warning, color: Colors.white, size: 30),
                            SizedBox(height: 8),
                            Text("Near Expiry",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 5),
                            Text("${nearExpiryMedicines.length} Items",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),

                // Low Stock Medicines
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                MedicineAlertsScreen(initialTab: 2)),
                      );
                    },
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.purple,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.warning_amber,
                                color: Colors.white, size: 30),
                            SizedBox(height: 8),
                            Text("Low Stock",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 5),
                            Text("${lowStockMedicines.length} Items",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Restock List
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RestockListScreen()),
                );
              },
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: Colors.teal,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory, color: Colors.white, size: 30),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Restock List",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 5),
                              Text("${lowStockMedicines.length} Items",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Revenue & Profit Graph
// Revenue & Profit Graph
  Widget _buildRevenueProfitGraph() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Revenue & Profit Trends",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DropdownButton<String>(
              value: selectedGraph,
              items: ["Revenue", "Profit"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedGraph = value!;
                });
              },
            ),
            DropdownButton<String>(
              value: selectedTimeFrame,
              items: ["Daily", "Weekly", "Monthly"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedTimeFrame = value!;
                });
              },
            ),
          ],
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true), // Corrected: gridData
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
              ),
              borderData: FlBorderData(show: true), // Corrected: borderData
              lineBarsData: [
                // Corrected: lineBarsData
                LineChartBarData(
                  spots: [
                    FlSpot(1, 10),
                    FlSpot(2, 20),
                    FlSpot(3, 35),
                    FlSpot(4, 50),
                    FlSpot(5, 70)
                  ],
                  isCurved: true,
                  gradient: LinearGradient(colors: [Colors.green, Colors.blue]),
                  barWidth: 4,
                  isStrokeCapRound: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Info Card
  Widget _buildInfoCard(
      IconData icon, String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: color,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 30),
              SizedBox(height: 8),
              Text(title,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text(value,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // Top Selling Medicines
  Widget _buildBestSellingList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Top Medicines",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        _buildMedicineCard("Paracetamol", "500 units sold"),
        _buildMedicineCard("Amoxicillin", "300 units sold"),
      ],
    );
  }

  Widget _buildMedicineCard(String name, String details) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(Icons.medication, color: Colors.green),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(details),
      ),
    );
  }
}
