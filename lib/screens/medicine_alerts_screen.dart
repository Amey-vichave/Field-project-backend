import 'package:flutter/material.dart';

class MedicineAlertsScreen extends StatefulWidget {
  final int initialTab;

  const MedicineAlertsScreen({super.key, required this.initialTab});

  @override
  _MedicineAlertsScreenState createState() => _MedicineAlertsScreenState();
}

class _MedicineAlertsScreenState extends State<MedicineAlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dummy Data (Replace with database data)
  final List<Map<String, String>> expiredMedicines = [
    {"name": "Amoxicillin", "expiry": "05/2024"},
    {"name": "Cough Syrup", "expiry": "08/2024"},
  ];

  final List<Map<String, String>> nearExpiryMedicines = [
    {"name": "Paracetamol", "expiry": "12/2025"},
    {"name": "Ibuprofen", "expiry": "10/2024"},
  ];

  final List<Map<String, String>> lowStockMedicines = [
    {"name": "Vitamin C", "stock": "5"},
    {"name": "Pain Reliever", "stock": "3"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Stock Alerts"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.cancel, color: Colors.red), text: "Expired"),
            Tab(icon: Icon(Icons.warning, color: Colors.orange), text: "Near Expiry"),
            Tab(icon: Icon(Icons.warning_amber, color: Colors.purple), text: "Low Stock"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(expiredMedicines, "Expiry Date"),
          _buildList(nearExpiryMedicines, "Expiry Date"),
          _buildList(lowStockMedicines, "Stock Left"),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, String>> items, String label) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(Icons.medication, color: Colors.green),
            title: Text(items[index]["name"] ?? ""),
            subtitle: Text("$label: ${items[index][label.toLowerCase()]}"),
          ),
        );
      },
    );
  }
}
